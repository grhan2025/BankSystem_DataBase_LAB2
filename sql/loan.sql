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


-- =========================================================
-- 6. MySQL Event Scheduler 配置（可选自动化）
--    如果想让贷款自动在每月1号补息，取消下面注释
-- =========================================================

-- SET GLOBAL event_scheduler = ON;  -- 【需要管理员权限】

-- DROP EVENT IF EXISTS monthly_interest_event;
-- DELIMITER //
-- CREATE EVENT monthly_interest_event
-- ON SCHEDULE EVERY 1 MONTH
-- STARTS '2026-07-01 00:00:00'
-- DO
-- BEGIN
--     CALL apply_saving_interest();
--     CALL apply_loan_interest();
-- END //
-- DELIMITER ;
-- =========================================================
-- 2. 查询所有贷款流水 (支持首页正常开启，补齐 Django 所需的完整基础字段)
-- =========================================================
DROP PROCEDURE IF EXISTS get_all_loans;
DELIMITER //
CREATE PROCEDURE get_all_loans()
BEGIN
    SELECT
        loan_id,         -- [0]
        client_id,       -- [1]
        bank_name,       -- [2]
        loan_money,      -- [3]
        loan_rate,       -- [4]
        loan_date,       -- [5]
        get_remaining_loan_amount(loan_id), -- [6] (保留原索引)
        account_id       -- [7] (新加字段放在最后)
    FROM loan;
END //
DELIMITER ;

-- =========================================================
-- 3. 按贷款 ID 查询单条记录 (🔥 彻底根治 1305 view_loan 报错)
-- =========================================================
DROP PROCEDURE IF EXISTS get_loan_by_id;
DELIMITER //
CREATE PROCEDURE get_loan_by_id(IN p_loan_id VARCHAR(32))
BEGIN
    SELECT 
        l.loan_id, l.client_id, l.bank_name, l.loan_money, 
        l.loan_rate, l.loan_date, c.name, 
        get_remaining_loan_amount(l.loan_id),
        l.account_id -- 新加字段
    FROM loan l
    JOIN client c ON l.client_id = c.client_id
    WHERE l.loan_id = p_loan_id;
END //
DELIMITER ;

-- =========================================================
-- 4. 创建贷款存储过程 (保留)
-- =========================================================
DROP PROCEDURE IF EXISTS add_loan;
DELIMITER //
CREATE PROCEDURE add_loan(
    IN p_loan_id VARCHAR(32),
    IN p_client_id VARCHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_account_id CHAR(18), -- 【新加参数】接收绑定的账户ID
    IN p_loan_money DECIMAL(15,2),
    IN p_loan_rate DECIMAL(5,4),
    IN p_loan_date DATE
)
BEGIN
    -- 执行插入，包含新属性 account_id
    INSERT INTO loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date)
    VALUES (p_loan_id, p_client_id, p_bank_name, p_account_id, p_loan_money, p_loan_rate, p_loan_date);
END //
DELIMITER ;

-- =========================================================
-- 5. 搜索贷款存储过程 (保持原有结构并优化返回列)
-- =========================================================
DROP PROCEDURE IF EXISTS search_loan;
DELIMITER //
CREATE PROCEDURE search_loan(
    IN p_loan_id VARCHAR(32), IN p_client_id VARCHAR(18), 
    IN p_bank_name VARCHAR(30), IN p_name VARCHAR(30)
)
BEGIN
    SELECT l.loan_id, l.client_id, l.bank_name, l.loan_money, l.loan_rate, l.loan_date, 
           get_remaining_loan_amount(l.loan_id), l.account_id
    FROM loan l
    JOIN client c ON l.client_id = c.client_id
    WHERE (p_loan_id IS NULL OR l.loan_id LIKE CONCAT('%', p_loan_id, '%'))
      AND (p_client_id IS NULL OR l.client_id LIKE CONCAT('%', p_client_id, '%'))
      AND (p_bank_name IS NULL OR l.bank_name LIKE CONCAT('%', p_bank_name, '%'))
      AND (p_name IS NULL OR c.name LIKE CONCAT('%', p_name, '%'));
END //
DELIMITER ;

-- =========================================================
-- 6. 联动账户扣款与还款存储过程 (🔥 核心修改：对齐 5 参数)
-- =========================================================
DROP PROCEDURE IF EXISTS add_loan_payment;
DELIMITER //
CREATE PROCEDURE add_loan_payment(
    IN p_payment DECIMAL(15,2),     -- 1. 还款金额 (pay_money)
    IN p_payment_date DATE,         -- 2. 结算日期 (pay_date)
    IN p_loan_id VARCHAR(32),       -- 3. 贷款单号 (loan_id)
    IN p_account_id CHAR(18),       -- 4. 客户扣款账户 (account_id)
    IN p_account_type VARCHAR(10)   -- 5. 账户类型 ('saving' 储蓄 / 'credit' 信用)
)
BEGIN
    DECLARE v_current_balance DECIMAL(15,2);
    DECLARE v_remaining_loan DECIMAL(15,2);
    
    -- 事务级异常处理器：出错自动回滚，并将标准错误抛给 Python views
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 校验 1：确保目标贷款关系真实存在
    IF NOT EXISTS (SELECT 1 FROM loan WHERE loan_id = p_loan_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '还款失败：该贷款记录不存在！';
    END IF;

    -- 校验 2：拦截过度还款行为
    SET v_remaining_loan = get_remaining_loan_amount(p_loan_id);
    IF p_payment > v_remaining_loan THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '超过剩余贷款金额';
    END IF;

    -- 校验 3 & 4：动态获取并验证卡内可用资产是否充足
    IF p_account_type = 'saving' THEN
        SELECT balance INTO v_current_balance FROM saving_account WHERE account_id = p_account_id;
    ELSE
        SELECT balance INTO v_current_balance FROM credit_account WHERE account_id = p_account_id;
    END IF;

    IF v_current_balance < p_payment THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '账户余额不足';
    END IF;

    -- 动作 1：自动划扣客户对应的活期/信用账户卡内余额
    IF p_account_type = 'saving' THEN
        UPDATE saving_account SET balance = balance - p_payment WHERE account_id = p_account_id;
    ELSE
        UPDATE credit_account SET balance = balance - p_payment WHERE account_id = p_account_id;
    END IF;

    -- 动作 2：生成并插入正式还款流水凭证
    -- 注意：在此处执行 INSERT 操作后，你的触发器 after_pay_loan_insert 就会被自动激活！
    -- 它会自动帮你在对应银行的 Bank.asset 字段上追加 p_payment，从而完成整体资产流转闭环。
    INSERT INTO pay_loan(pay_money, pay_date, loan_id) 
    VALUES(p_payment, p_payment_date, p_loan_id);

    COMMIT;
END //
DELIMITER ;
DROP PROCEDURE IF EXISTS get_loan_payment;
DELIMITER //

CREATE PROCEDURE get_loan_payment(
    IN p_loan_id VARCHAR(32)
)
BEGIN
    SELECT
        pay_id,
        pay_money,
        pay_date
    FROM pay_loan
    WHERE loan_id = p_loan_id
    ORDER BY pay_date;
END //

DELIMITER ;
DELIMITER //

DROP PROCEDURE IF EXISTS delete_loan;
CREATE PROCEDURE delete_loan(
    IN p_loan_id VARCHAR(32)
)
BEGIN
    DECLARE v_remain DECIMAL(15,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 只执行一次计算，结果存入变量，全程复用
    SELECT get_remaining_loan_amount(p_loan_id) INTO v_remain;

    IF v_remain > 0.00 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = '风控拦截：该贷款流水单尚未结清，禁止强行删除记录！';
    END IF;

    -- 校验通过再删数据
    DELETE FROM pay_loan WHERE loan_id = p_loan_id;
    DELETE FROM loan WHERE loan_id = p_loan_id;

    COMMIT;
END //
DELIMITER ;

DELIMITER ;