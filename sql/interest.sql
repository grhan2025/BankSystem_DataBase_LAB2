use banksystem;

-- =========================================================
-- 1. 修改 get_remaining_loan_amount 函数：加入利息
-- =========================================================
DROP FUNCTION IF EXISTS get_remaining_loan_amount;
DELIMITER //
CREATE FUNCTION get_remaining_loan_amount(p_loan_id VARCHAR(32))
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE total_loan      DECIMAL(15,2);
    DECLARE total_paid      DECIMAL(15,2);
    DECLARE total_interest  DECIMAL(15,2);

    SELECT loan_money, IFNULL(accrued_interest, 0)
    INTO total_loan, total_interest
    FROM loan WHERE loan_id = p_loan_id;

    SELECT IFNULL(SUM(pay_money), 0)
    INTO total_paid
    FROM pay_loan WHERE loan_id = p_loan_id;

    -- 剩余 = 本金 + 累计利息 - 已还款
    RETURN total_loan + total_interest - total_paid;
END //
DELIMITER ;


-- =========================================================
-- 2. 贷款补息过程：查询时自动补算历史缺失的利息
--    （解决"跨过1号没结的息"问题）
-- =========================================================
DROP PROCEDURE IF EXISTS ensure_loan_interest_up_to_date;
DELIMITER //
CREATE PROCEDURE ensure_loan_interest_up_to_date(IN p_loan_id VARCHAR(32))
BEGIN
    DECLARE v_last_date     DATE;
    DECLARE v_check_date    DATE;
    DECLARE v_loan_money    DECIMAL(15,2);
    DECLARE v_paid          DECIMAL(15,2);
    DECLARE v_old_interest  DECIMAL(15,2);
    DECLARE v_rate          DECIMAL(5,4);
    DECLARE v_principal     DECIMAL(15,2);
    DECLARE v_new_interest  DECIMAL(15,2);
    DECLARE v_days          INT;

    SELECT loan_money, loan_rate,
           IFNULL(last_interest_date, loan_date),
           IFNULL(accrued_interest, 0)
    INTO v_loan_money, v_rate, v_last_date, v_old_interest
    FROM loan WHERE loan_id = p_loan_id;

    -- 从上次结息日开始，逐月补算（每月1号各结一次）
    SET v_check_date = DATE(CONCAT(
        YEAR(v_last_date + INTERVAL 1 MONTH), '-',
        MONTH(v_last_date + INTERVAL 1 MONTH), '-01'
    ));

    -- 循环逐月计息，直到达到今天
    WHILE v_check_date <= CURDATE() DO
        SET v_days = DATEDIFF(v_check_date, v_last_date);

        -- 查询该月截止时已还款总额
        SELECT IFNULL(SUM(pay_money), 0) INTO v_paid
        FROM pay_loan WHERE loan_id = p_loan_id;

        -- 计息基数 = 原始本金 - (已还款 - 之前的利息)
        -- 这保证了只对"纯本金"部分计息，不会复利
        SET v_principal = v_loan_money - GREATEST(v_paid - v_old_interest, 0);
        SET v_principal = GREATEST(v_principal, 0);

        -- 本月利息 = 剩余本金 × 年利率 × 天数/365
        SET v_new_interest = ROUND(v_principal * v_rate * v_days / 365, 2);

        -- 写入数据库：累加利息，更新最后结息日期
        UPDATE loan
        SET accrued_interest   = accrued_interest + v_new_interest,
            last_interest_date = v_check_date
        WHERE loan_id = p_loan_id;

        -- 变量递进（为下一月做准备）
        SET v_old_interest = v_old_interest + v_new_interest;
        SET v_last_date    = v_check_date;
        SET v_check_date   = v_check_date + INTERVAL 1 MONTH;
    END WHILE;
END //
DELIMITER ;


-- =========================================================
-- 3. 储蓄账户结息过程（每月调用一次）
--    直接加入 balance，触发 after_saving_account_update 自动同步资产
-- =========================================================
DROP PROCEDURE IF EXISTS apply_saving_interest;
DELIMITER //
CREATE PROCEDURE apply_saving_interest()
BEGIN
    -- 简单做法：每次调用结 30 天利息（对应月周期）
    -- 这样每月1号调用一次，就是每月结息，不会重复
    UPDATE saving_account
    SET balance = ROUND(balance + balance * rate * 30 / 365, 2);
END //
DELIMITER ;


-- =========================================================
-- 4. 贷款结息过程：对所有未结清贷款补算利息
--    (可选：如果要按月自动结息，MySQL Event Scheduler 调用它)
-- =========================================================
DROP PROCEDURE IF EXISTS apply_loan_interest;
DELIMITER //
CREATE PROCEDURE apply_loan_interest()
BEGIN
    DECLARE v_loan_id       VARCHAR(32);
    DECLARE done            INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT loan_id FROM loan
        WHERE get_remaining_loan_amount(loan_id) > 0;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_loan_id;
        IF done THEN LEAVE read_loop; END IF;
        CALL ensure_loan_interest_up_to_date(v_loan_id);
    END LOOP;
    CLOSE cur;
END //
DELIMITER ;


-- =========================================================
-- 5. 查询单笔贷款的利息明细（用于前端展示）
-- =========================================================
DROP PROCEDURE IF EXISTS get_loan_interest_detail;
DELIMITER //
CREATE PROCEDURE get_loan_interest_detail(IN p_loan_id VARCHAR(32))
BEGIN
    -- 先补息
    CALL ensure_loan_interest_up_to_date(p_loan_id);

    SELECT
        l.loan_id,
        l.loan_money,
        l.loan_rate,
        l.loan_date,
        l.accrued_interest,
        l.last_interest_date,
        get_remaining_loan_amount(l.loan_id) AS total_remaining,
        -- 纯本金剩余（不含利息）
        l.loan_money - GREATEST(
            IFNULL((SELECT SUM(pay_money) FROM pay_loan WHERE loan_id = l.loan_id), 0)
            - l.accrued_interest, 0
        ) AS principal_remaining
    FROM loan l
    WHERE l.loan_id = p_loan_id;
END //
DELIMITER ;

-- ALTER TABLE saving_account 
-- ADD COLUMN last_interest_date DATE DEFAULT NULL,
-- ADD COLUMN accrued_interest DECIMAL(15, 2) DEFAULT 0.00;
DELIMITER //

DROP PROCEDURE IF EXISTS ensure_saving_interest_up_to_date //

CREATE PROCEDURE ensure_saving_interest_up_to_date(IN p_account_id CHAR(18))
proc_label: BEGIN  -- 1. 添加标签
    DECLARE v_last_date DATE;
    DECLARE v_balance DECIMAL(15,2);
    DECLARE v_rate DECIMAL(5,4);
    DECLARE v_interest_days INT;
    DECLARE v_interest DECIMAL(15,2);

    -- 获取账户信息
    SELECT balance, rate, IFNULL(last_interest_date, open_date) 
    INTO v_balance, v_rate, v_last_date
    FROM saving_account WHERE account_id = p_account_id;

    -- 如果还没到结息日，直接退出
    IF v_last_date >= CURDATE() THEN
        LEAVE proc_label; -- 2. 使用标签退出
    END IF;

    -- 计算天数并计算利息
    SET v_interest_days = DATEDIFF(CURDATE(), v_last_date);
    SET v_interest = v_balance * v_rate * (v_interest_days / 365);

    -- 更新余额和最后结息日期
    UPDATE saving_account 
    SET balance = balance + v_interest,
        last_interest_date = CURDATE()
    WHERE account_id = p_account_id;
    
END proc_label // -- 3. 结束标签

DELIMITER ;