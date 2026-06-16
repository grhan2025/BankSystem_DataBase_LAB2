use banksystem;

-- 添加用户 存储过程
drop procedure if exists add_client;
delimiter //
create procedure add_client(
    in p_client_id varchar(18),
    in p_id varchar(18),
    in p_name varchar(30),
    in p_sex varchar(1),
    in p_address varchar(30),
    in p_phone varchar(30),
    in p_email varchar(30),
    in p_contact_name varchar(30),
    in p_contact_phone varchar(20),
    in p_contact_email varchar(30),
    in p_contact_relation varchar(20),
    out p_error varchar(255)
)
begin
    declare exit handler for sqlexception
    begin
        set p_error = 'Error occurred while adding client.';
        rollback;
    end;

    start transaction;

    insert into client (client_id, id, name, sex, address, phone, email,contact_name, contact_phone, contact_email, contact_relation)
    values (p_client_id, p_id, p_name, p_sex, p_address, p_phone, p_email, p_contact_name, p_contact_phone, p_contact_email, p_contact_relation);

    commit;
    set p_error = '';
end //
delimiter;

-- 查询所有用户存储过程
drop procedure if exists get_all_clients;
delimiter //
CREATE PROCEDURE get_all_clients()
BEGIN
    SELECT * FROM client;
END //
delimiter ;

DELIMITER //
DROP PROCEDURE IF EXISTS delete_client //
CREATE PROCEDURE delete_client(
    IN p_client_id VARCHAR(18),
    OUT p_error VARCHAR(255)
)
BEGIN
    -- 定义错误处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @msg = MESSAGE_TEXT;
        -- 强制将捕获到的错误赋值给输出变量
        SET p_error = @msg;
        ROLLBACK;
    END;

    START TRANSACTION;

    -- 检查客户是否存在
    IF NOT EXISTS (SELECT 1 FROM client WHERE client_id = p_client_id) THEN
        SET p_error = '错误：找不到该客户';
        ROLLBACK;
    ELSE
        -- 尝试删除账户 (如果此时触发器被激活，会跳转到上面的 EXIT HANDLER)
        DELETE FROM saving_account WHERE client_id = p_client_id;
        DELETE FROM credit_account WHERE client_id = p_client_id;
        
        -- 最后删除客户
        DELETE FROM client WHERE client_id = p_client_id;
        
        COMMIT;
        SET p_error = ''; -- 成功
    END IF;
END //
DELIMITER ;
-- 修改用户信息存储过层

drop procedure if exists modify_client;
delimiter //
create procedure modify_client(
    IN p_client_id VARCHAR(18),
    IN p_id VARCHAR(18),
    IN p_name VARCHAR(30),
    IN p_sex VARCHAR(1),
    IN p_address VARCHAR(30),
    IN p_phone VARCHAR(30),
    IN p_email VARCHAR(30),
    IN p_contact_name VARCHAR(30),
    IN p_contact_phone VARCHAR(20),
    IN p_contact_email VARCHAR(30),
    IN p_contact_relation VARCHAR(20),
    OUT p_error VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_error = 'Error occurred while modifying client.';
        ROLLBACK;
    END;

    START TRANSACTION;

    IF p_id IS NOT NULL AND p_id != '' THEN
        UPDATE client SET id = p_id WHERE client_id = p_client_id;
    END IF;

    IF p_name IS NOT NULL AND p_name != '' THEN
        UPDATE client SET name = p_name WHERE client_id = p_client_id;
    END IF;

    IF p_sex IS NOT NULL AND p_sex != '' THEN
        UPDATE client SET sex = p_sex WHERE client_id = p_client_id;
    END IF;

    IF p_address IS NOT NULL AND p_address != '' THEN
        UPDATE client SET address = p_address WHERE client_id = p_client_id;
    END IF;

    IF p_phone IS NOT NULL AND p_phone != '' THEN
        UPDATE client SET phone = p_phone WHERE client_id = p_client_id;
    END IF;

    IF p_email IS NOT NULL AND p_email != '' THEN
        UPDATE client SET email = p_email WHERE client_id = p_client_id;
    END IF;

    IF p_contact_name IS NOT NULL AND p_contact_name != '' THEN
        UPDATE client SET contact_name = p_contact_name WHERE client_id = p_client_id;
    END IF;

    IF p_contact_phone IS NOT NULL AND p_contact_phone != '' THEN
        UPDATE client SET contact_phone = p_contact_phone WHERE client_id = p_client_id;
    END IF;

    IF p_contact_email IS NOT NULL AND p_contact_email != '' THEN
        UPDATE client SET contact_email = p_contact_email WHERE client_id = p_client_id;
    END IF;

    IF p_contact_relation IS NOT NULL AND p_contact_relation != '' THEN
        UPDATE client SET contact_relation = p_contact_relation WHERE client_id = p_client_id;
    END IF;

    COMMIT;
    SET p_error = '';
END //
delimiter ;

-- 查询用户信息存储过程
drop procedure if exists search_client;
delimiter //
create procedure search_client(
    in p_client_id varchar(18),
    in p_name varchar(30)
)
begin
    select * from client
    where (p_client_id is null or client_id like concat('%', p_client_id, '%'))
    and (p_name is null or name like concat('%', p_name, '%'));
end //
delimiter ;


-- 查看用户具体信息存储过程
DROP PROCEDURE IF EXISTS get_client_detail;
DELIMITER //
CREATE PROCEDURE get_client_detail(
    IN p_client_id VARCHAR(18)
)
BEGIN
    SELECT client_id, id, name, sex, address, phone, email, contact_name, contact_phone, contact_email, contact_relation
    FROM client
    WHERE client_id = p_client_id;
END //
DELIMITER ;