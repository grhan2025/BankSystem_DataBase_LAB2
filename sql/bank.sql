use banksystem;
-- 获取所有银行信息的存储过程
DROP PROCEDURE IF EXISTS GetAllBanks;
DELIMITER //

CREATE PROCEDURE GetAllBanks()
BEGIN
    SELECT 
        b.bank_name, 
        b.location, 
        b.asset, 
        b.image,
        -- 1. 统计总贷款额 (从 loan 表统计)
        COALESCE((SELECT SUM(l.loan_money) FROM loan l WHERE l.bank_name = b.bank_name), 0) AS total_loans,
        -- 2. 统计总账户数 (储蓄账户数量 + 信用账户数量)
        (
            COALESCE((SELECT COUNT(*) FROM saving_account sa WHERE sa.bank_name = b.bank_name), 0) + 
            COALESCE((SELECT COUNT(*) FROM credit_account ca WHERE ca.bank_name = b.bank_name), 0)
        ) AS total_accounts,
        -- 3. 统计该银行的不重复客户总数 (合并统计贷款客户、储蓄客户、信用客户)
        (
            SELECT COUNT(DISTINCT client_id) FROM (
                SELECT client_id, bank_name FROM loan
                UNION
                SELECT client_id, bank_name FROM saving_account
                UNION
                SELECT client_id, bank_name FROM credit_account
            ) AS combined_clients WHERE combined_clients.bank_name = b.bank_name
        ) AS total_clients
    FROM Bank b;
END //

DELIMITER ;

DROP PROCEDURE IF EXISTS GetBankStatistics;
DELIMITER //
CREATE PROCEDURE GetBankStatistics()
BEGIN
    -- 假设你的 Bank 表、贷款表、账户表等通过 bank_name 关联
    SELECT 
        b.bank_name, 
        b.location, 
        b.asset,
        b.image,
        COALESCE(SUM(l.loan_money), 0) AS total_loan,
        -- 这里根据你的实际表结构计算账户数和客户数
        0 AS total_account, 
        0 AS total_client
    FROM Bank b
    LEFT JOIN loan l ON b.bank_name = l.bank_name
    GROUP BY b.bank_name;
END //
DELIMITER ;
-- 添加银行信息的存储过程
drop procedure if exists AddBank;
delimiter //
CREATE PROCEDURE AddBank(
    IN p_bank_name VARCHAR(30),
    IN p_location VARCHAR(30),
    IN p_asset FLOAT,
    IN p_image VARCHAR(255)
)
BEGIN
    DECLARE asset_limit_reached BOOLEAN DEFAULT FALSE;

    if p_asset < 0 THEN
        set asset_limit_reached = TRUE;
    end if;

    if asset_limit_reached THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bank asset cannot be negative';
    else
        INSERT INTO Bank (bank_name, location, asset, image) VALUES (p_bank_name, p_location, p_asset, p_image);
    end if;
END //
delimiter ;

-- 修改银行信息的存储过程
drop procedure if exists UpdateBank;
DELIMITER //
CREATE PROCEDURE UpdateBank(
    IN p_bank_name VARCHAR(30),
    IN p_location VARCHAR(30),
    IN p_asset FLOAT,
    IN p_image VARCHAR(255)
)
BEGIN
    UPDATE Bank 
    SET location = p_location, asset = p_asset, image = p_image
    WHERE bank_name = p_bank_name;
END //
DELIMITER ;

-- 删除银行信息的存储过程
-- 删除银行信息的存储过程 (升级版：带安全校验的级联删除)
DROP PROCEDURE IF EXISTS DeleteBank;
DELIMITER //

CREATE PROCEDURE DeleteBank(
    IN p_bank_name VARCHAR(30)
)
BEGIN
    -- 1. 声明异常处理器：如果触发器抛出错误，直接回滚并把错误传给后端
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    -- 2. 开启事务，确保要么全部删干净，要么原封不动
    START TRANSACTION;

    -- 3. 显式删除该银行的所有储蓄账户
    -- 【关键】：由于这里是显式执行 DELETE，它会完美唤醒 before_saving_account_delete 触发器！
    -- 如果有任何一个账户余额 > 0，触发器会报错，事务直接回滚。
    DELETE FROM saving_account WHERE bank_name = p_bank_name;

    -- 4. 显式删除该银行的所有信用账户
    -- 同理，唤醒 before_credit_account_delete 触发器，校验贷款和余额。
    DELETE FROM credit_account WHERE bank_name = p_bank_name;

    -- 5. 如果上面两步顺利执行（没有触发器报错），说明账户全清空了
    -- 此时可以安全地删除银行本身。
    -- （注：由于你的 department 表有 ON DELETE CASCADE，部门和员工也会被自动安全清理）
    DELETE FROM Bank WHERE bank_name = p_bank_name;

    -- 6. 提交事务
    COMMIT;
END //
DELIMITER ;
-- 查找银行信息的存储过程
drop procedure if exists GetBankByName;
DELIMITER //
CREATE PROCEDURE GetBankByName(
    IN p_bank_name VARCHAR(30)
)
BEGIN
    SELECT bank_name, location, asset, image
    FROM Bank 
    WHERE bank_name = p_bank_name;
END //
DELIMITER ;

-- 查找银行信息的存储过程
DROP PROCEDURE IF EXISTS search_bank;
DELIMITER //
CREATE PROCEDURE search_bank(
    IN p_bank_name VARCHAR(30),
    IN p_location VARCHAR(30)
)
BEGIN
    SELECT bank_name, location, asset, image
    FROM Bank
    WHERE (p_bank_name IS NULL OR bank_name LIKE CONCAT('%', p_bank_name, '%'))
    AND (p_location IS NULL OR location LIKE CONCAT('%', p_location, '%'));
END //
DELIMITER ;

-- 获取所有部门信息的存储过程
DROP PROCEDURE IF EXISTS get_departments_by_bank;

DELIMITER //

CREATE PROCEDURE get_departments_by_bank (
    IN p_bank_name VARCHAR(30)
)
BEGIN
    SELECT * FROM department
    WHERE bank_name = p_bank_name;
END //

DELIMITER ;