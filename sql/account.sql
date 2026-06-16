use banksystem;

-- 创建储蓄账户存储过程
drop procedure if exists create_saving_account;
delimiter //
CREATE PROCEDURE create_saving_account(
    IN p_account_id CHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_balance FLOAT,
    IN p_open_date DATE,
    IN p_rate FLOAT,
    IN p_client_id VARCHAR(18)
)
BEGIN
    IF (SELECT COUNT(*) FROM Bank WHERE bank_name = p_bank_name) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bank does not exist';
    ELSEIF (SELECT COUNT(*) FROM client WHERE client_id = p_client_id) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Client does not exist';
    ELSE
        INSERT INTO saving_account(account_id, bank_name, client_id, balance, open_date, rate)
        VALUES (p_account_id, p_bank_name, p_client_id, p_balance, p_open_date, p_rate);
    END IF;
END //
delimiter ;

-- 创建信用账户存储过程
drop procedure if exists create_credit_account;
delimiter //
CREATE PROCEDURE create_credit_account(
    IN p_account_id CHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_balance FLOAT,
    IN p_open_date DATE,
    IN p_overdraft FLOAT,
    IN p_client_id VARCHAR(18)
)
BEGIN
    IF (SELECT COUNT(*) FROM Bank WHERE bank_name = p_bank_name) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bank does not exist';
    ELSEIF (SELECT COUNT(*) FROM client WHERE client_id = p_client_id) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Client does not exist';
    ELSE
        INSERT INTO credit_account(account_id, bank_name, client_id, balance, open_date, overdraft)
        VALUES (p_account_id, p_bank_name, p_client_id, p_balance, p_open_date, p_overdraft);
    END IF;
END //
delimiter ;

-- 一键查询储蓄账户存储过程
drop procedure if exists get_saving_account_by_all;
delimiter //
create procedure get_saving_account_by_all()
begin
    SELECT sa.account_id, sa.bank_name, 'saving' AS account_type, sa.client_id
    FROM saving_account sa;
end //
delimiter ;

-- 一键查询信用账户存储过程
drop procedure if exists get_credit_account_by_all;
delimiter //
create procedure get_credit_account_by_all()
begin
    SELECT ca.account_id, ca.bank_name, 'credit' AS account_type, ca.client_id
    FROM credit_account ca;
end //
delimiter ;

-- 根据account_id查询储蓄账户存储过程
drop procedure if exists get_saving_account_by_id;
delimiter //
create procedure get_saving_account_by_id(
    IN p_account_id CHAR(18)
)
begin
    SELECT sa.account_id, sa.bank_name, sa.balance, sa.open_date, 'saving' AS account_type,
           sa.rate, sa.client_id, c.name
    FROM saving_account sa
    JOIN client c ON sa.client_id = c.client_id
    WHERE sa.account_id = p_account_id;
end //
delimiter ;

-- 根据account_id查询信用账户存储过程
drop procedure if exists get_credit_account_by_id;
delimiter //
create procedure get_credit_account_by_id(
    IN p_account_id CHAR(18)
)
begin
    SELECT ca.account_id, ca.bank_name, ca.balance, ca.open_date, 'credit' AS account_type,
           ca.overdraft, ca.client_id, c.name
    FROM credit_account ca
    JOIN client c ON ca.client_id = c.client_id
    WHERE ca.account_id = p_account_id;
end //
delimiter ;

-- 根据account_id修改储蓄账户存储过程
drop procedure if exists update_saving_account_by_account_id;
delimiter //
create procedure update_saving_account_by_account_id(
    IN p_account_id CHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_balance FLOAT,
    IN p_rate FLOAT
)
begin
    IF (SELECT COUNT(*) FROM Bank WHERE bank_name = p_bank_name) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bank does not exist';
    ELSE
        UPDATE saving_account
        SET bank_name = p_bank_name, balance = p_balance, rate = p_rate
        WHERE account_id = p_account_id;
    END IF;
end //
delimiter ;

-- 根据account_id修改信用账户存储过程
drop procedure if exists update_credit_account_by_account_id;
delimiter //
create procedure update_credit_account_by_account_id(
    IN p_account_id CHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_balance FLOAT,
    IN p_overdraft FLOAT
)
begin
    IF (SELECT COUNT(*) FROM Bank WHERE bank_name = p_bank_name) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bank does not exist';
    ELSE
        UPDATE credit_account
        SET bank_name = p_bank_name, balance = p_balance, overdraft = p_overdraft
        WHERE account_id = p_account_id;
    END IF;
end //
delimiter ;

-- 根据account_id删除储蓄账户存储过程
drop procedure if exists delete_saving_account_by_account_id;
delimiter //
create procedure delete_saving_account_by_account_id(
    IN p_account_id CHAR(18)
)
begin
    DELETE FROM saving_account WHERE account_id = p_account_id;
end //
delimiter ;

-- 根据account_id删除信用账户存储过程
drop procedure if exists delete_credit_account_by_account_id;
delimiter //
create procedure delete_credit_account_by_account_id(
    IN p_account_id CHAR(18)
)
begin
    DELETE FROM credit_account WHERE account_id = p_account_id;
end //
delimiter ;

-- 搜索储蓄账户存储过程
DROP PROCEDURE IF EXISTS search_saving_account;
DELIMITER //
CREATE PROCEDURE search_saving_account(
    IN p_client_id VARCHAR(18),
    IN p_account_id CHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_name VARCHAR(30)
)
BEGIN
    SELECT sa.account_id, sa.bank_name, 'saving' AS account_type, sa.client_id
    FROM saving_account sa
    JOIN client c ON sa.client_id = c.client_id
    WHERE
        (p_client_id IS NULL OR sa.client_id LIKE CONCAT('%', p_client_id, '%'))
        AND (p_account_id IS NULL OR sa.account_id LIKE CONCAT('%', p_account_id, '%'))
        AND (p_bank_name IS NULL OR sa.bank_name LIKE CONCAT('%', p_bank_name, '%'))
        AND (p_name IS NULL OR c.name LIKE CONCAT('%', p_name, '%'));
END //
DELIMITER ;

-- 搜索信用账户存储过程
DROP PROCEDURE IF EXISTS search_credit_account;
DELIMITER //
CREATE PROCEDURE search_credit_account(
    IN p_client_id VARCHAR(18),
    IN p_account_id CHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_name VARCHAR(30)
)
BEGIN
    SELECT ca.account_id, ca.bank_name, 'credit' AS account_type, ca.client_id
    FROM credit_account ca
    JOIN client c ON ca.client_id = c.client_id
    WHERE
        (p_client_id IS NULL OR ca.client_id LIKE CONCAT('%', p_client_id, '%'))
        AND (p_account_id IS NULL OR ca.account_id LIKE CONCAT('%', p_account_id, '%'))
        AND (p_bank_name IS NULL OR ca.bank_name LIKE CONCAT('%', p_bank_name, '%'))
        AND (p_name IS NULL OR c.name LIKE CONCAT('%', p_name, '%'));
END //
DELIMITER ;