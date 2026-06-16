use banksystem;

-- 创建部门存储过程
drop procedure if exists add_department;
delimiter //
CREATE PROCEDURE add_department (
    IN p_department_id VARCHAR(18),
    IN p_bank_name VARCHAR(30),
    IN p_department_name VARCHAR(30),
    IN p_department_type VARCHAR(30)
)
BEGIN
    INSERT INTO department (department_id, bank_name, department_name, department_type)
    VALUES (p_department_id, p_bank_name, p_department_name, p_department_type);
END //
delimiter ;

-- 查询部门的存储过程
drop procedure if exists get_department_by_id;
delimiter //
CREATE PROCEDURE get_department_by_id (
    IN p_department_id VARCHAR(18)
)
BEGIN
    SELECT * FROM department WHERE department_id = p_department_id;
END //
delimiter ;

-- 修改部门的存储过程
drop procedure if exists update_department;
delimiter //
CREATE PROCEDURE update_department (
    IN p_department_id VARCHAR(18),
    IN p_department_name VARCHAR(30),
    IN p_department_type VARCHAR(30)
)
BEGIN
    UPDATE department SET department_name = p_department_name, department_type = p_department_type WHERE department_id = p_department_id;
END //
delimiter ;

-- 删除部门的存储过程
DROP PROCEDURE IF EXISTS delete_department;
DELIMITER //
CREATE PROCEDURE delete_department (
    IN p_department_id VARCHAR(18)
)
BEGIN
    DELETE FROM department WHERE department_id = p_department_id;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS search_department;
DELIMITER //
CREATE PROCEDURE search_department(
    IN p_department_id VARCHAR(18),
    IN p_department_name VARCHAR(30),
    IN p_bank_name VARCHAR(30)
)
BEGIN
    SELECT department_id, department_name, department_type, bank_name
    FROM department
    WHERE bank_name = p_bank_name
    AND (p_department_id IS NULL OR department_id LIKE CONCAT('%', p_department_id, '%'))
    AND (p_department_name IS NULL OR department_name LIKE CONCAT('%', p_department_name, '%'));
END //
DELIMITER ;