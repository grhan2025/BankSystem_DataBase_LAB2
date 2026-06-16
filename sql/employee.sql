use banksystem;

-- 查询员工的存储过程
DROP PROCEDURE IF EXISTS get_employee_by_id;
DELIMITER //
CREATE PROCEDURE get_employee_by_id (
    IN p_employee_id VARCHAR(18)
)
BEGIN
    SELECT * FROM employee WHERE employee_id = p_employee_id;
END //
DELIMITER ;

-- 创建员工的存储过程
DROP PROCEDURE IF EXISTS add_employee;
DELIMITER //
CREATE PROCEDURE add_employee (
    IN p_employee_id VARCHAR(18),
    IN p_department_id VARCHAR(18),
    IN p_id VARCHAR(18),
    IN p_name VARCHAR(30),
    IN p_sex VARCHAR(1),
    IN p_phone VARCHAR(30),
    IN p_address VARCHAR(30),
    IN p_start_work_date DATE
)
BEGIN
    INSERT INTO employee (employee_id, department_id, id, name, sex, phone, address, start_work_date)
    VALUES (p_employee_id, p_department_id, p_id, p_name, p_sex, p_phone, p_address, p_start_work_date);
END //
DELIMITER ;

-- 按部门号查询员工的存储过程
drop procedure if exists get_employee_by_department_id;
delimiter //
create procedure get_employee_by_department_id(
    in p_department_id varchar(18)
)
begin
    select * from employee where department_id = p_department_id;
end //
delimiter ;

-- 修改员工的存储过程
DROP PROCEDURE IF EXISTS update_employee;
DELIMITER //
CREATE PROCEDURE update_employee (
    IN p_employee_id VARCHAR(18),
    IN p_department_id VARCHAR(18),
    IN p_id VARCHAR(18),
    IN p_name VARCHAR(30),
    IN p_sex VARCHAR(1),
    IN p_phone VARCHAR(30),
    IN p_address VARCHAR(30),
    IN p_start_work_date DATE
)
BEGIN
    UPDATE employee SET department_id = p_department_id, id = p_id, name = p_name, sex = p_sex, phone = p_phone, address = p_address, start_work_date = p_start_work_date WHERE employee_id = p_employee_id;
END //
DELIMITER ;

-- 删除员工的存储过程
DROP PROCEDURE IF EXISTS delete_employee;
DELIMITER //
CREATE PROCEDURE delete_employee (
    IN p_employee_id VARCHAR(18)
)
BEGIN
    DELETE FROM employee WHERE employee_id = p_employee_id;
END //
DELIMITER ;

-- 查找员工的存储过程
DROP PROCEDURE IF EXISTS search_employee;
DELIMITER //
CREATE PROCEDURE search_employee(
    IN p_employee_id VARCHAR(18),
    IN p_name VARCHAR(30),
    IN p_department_id VARCHAR(18)
)
BEGIN
    SELECT employee_id, department_id, id, name, sex, phone, address, start_work_date
    FROM employee
    WHERE department_id = p_department_id 
    AND (name is null or name like concat('%', p_name, '%'))
    AND (employee_id is null or employee_id like concat('%', p_employee_id, '%'));
END //
DELIMITER ;