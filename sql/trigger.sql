use banksystem;

-- =========================================================
-- 1. 储蓄账户（Saving Account）相关触发器
-- =========================================================
drop trigger if exists after_saving_account_insert;
delimiter //
create trigger after_saving_account_insert
after insert on saving_account
for each row
begin
    update Bank set asset = asset + new.balance where bank_name = new.bank_name;
end ;
//
delimiter ;

drop trigger if exists after_saving_account_update;
delimiter //
create trigger after_saving_account_update
after update on saving_account
for each row
begin
    update Bank set asset = asset - old.balance + new.balance where bank_name = new.bank_name;
end ;
//
delimiter ;

-- 储蓄账户销户：卡住存款余额即可
drop trigger if exists before_saving_account_delete;
delimiter //
create trigger before_saving_account_delete
before delete on saving_account
for each row
begin
    if old.balance > 0 then
        signal sqlstate '45000' set message_text = '销户失败：该储蓄账户内仍有存款余额，请先办理取款清户！';
    end if;
    update Bank set asset = asset - old.balance where bank_name = old.bank_name;
end ;
//
delimiter ;


-- =========================================================
-- 2. 信用账户（Credit Account）相关触发器
-- =========================================================
-- 信用账户销户：允许存在贷款记录，但必须全部还清
drop trigger if exists before_credit_account_delete;
delimiter //
create trigger before_credit_account_delete
before delete on credit_account
for each row
begin
    DECLARE v_remaining_total DECIMAL(15, 2) DEFAULT 0.00;

    -- 【精准风控升级】累计计算当前要删除的账户下，所有关联贷款的剩余未还本金
    SELECT IFNULL(SUM(get_remaining_loan_amount(loan_id)), 0) 
    INTO v_remaining_total 
    FROM loan 
    WHERE account_id = OLD.account_id;

    -- 如果剩余未还总额大于 0，说明存在未还清的贷款，拦截销户
    IF v_remaining_total > 0 THEN
        signal sqlstate '45000' 
        set message_text = '销户失败：该信用账户下尚有未还清的贷款，请先结清全部贷款！';
    END IF;

    -- 检查卡内本身的存款或透支余额情况
    if old.balance != 0 then
        if old.balance > 0 then
            signal sqlstate '45000' set message_text = '销户失败：该信用账户内仍有预存款（余额），请先取回资金！';
        else
            signal sqlstate '45000' set message_text = '销户失败：该信用账户尚有透支欠款未还清，请先还款！';
        end if;
    end if;

    -- 同步扣减银行资产
    update Bank set asset = asset - old.balance where bank_name = old.bank_name;
end ;
//
delimiter ;


-- =========================================================
-- 3. 贷款（Loan）相关风控触发器
-- =========================================================
-- 申请贷款前：精准校验账户合法性与银行资产
DELIMITER //
DROP TRIGGER IF EXISTS before_loan_insert //
CREATE TRIGGER before_loan_insert
BEFORE INSERT ON loan
FOR EACH ROW
BEGIN
    DECLARE v_overdraft DECIMAL(15,2);
    DECLARE v_total_remaining DECIMAL(15,2);
    DECLARE v_bank_asset DECIMAL(15,2);

    -- 1. 检查账户合法性：确保账户属于该客户且属于该银行
    IF NOT EXISTS (
        SELECT 1 FROM credit_account 
        WHERE account_id = NEW.account_id 
          AND client_id = NEW.client_id 
          AND bank_name = NEW.bank_name
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '贷款申请失败：信用账户不匹配或不存在！';
    END IF;

    -- 2. 计算该账户的透支总额度
    SELECT overdraft INTO v_overdraft FROM credit_account WHERE account_id = NEW.account_id;

    -- 3. 计算该账户当前已占用的额度 (只算该 account_id 下的贷款)
    SELECT IFNULL(SUM(get_remaining_loan_amount(loan_id)), 0) 
    INTO v_total_remaining 
    FROM loan 
    WHERE account_id = NEW.account_id;

    -- 4. 核心校验：校验本次贷款金额是否会超出剩余额度
    IF (v_total_remaining + NEW.loan_money) > v_overdraft THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '贷款发放失败：该账户可用额度不足！';
    END IF;

    -- 5. 检查银行资产
    SELECT asset INTO v_bank_asset FROM bank WHERE bank_name = NEW.bank_name;
    IF v_bank_asset < NEW.loan_money THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '贷款发放失败：银行资产储备不足';
    END IF;
END //
DELIMITER ;
-- 放贷后扣减银行资产
drop trigger if exists after_loan_insert;
delimiter //
create trigger after_loan_insert
after insert on loan
for each row
begin
    update Bank set asset = asset - new.loan_money where bank_name = new.bank_name;
end ;
//
delimiter ;

-- 还贷后增加银行资产
drop trigger if exists after_pay_loan_insert;
delimiter //
create trigger after_pay_loan_insert
after insert on pay_loan
for each row
begin
    update Bank set asset = asset + new.pay_money where bank_name = (select bank_name from loan where loan_id = new.loan_id);
end ;
//
delimiter ;

-- 2. 重写信用账户删除触发器：移除 CALL delete_loan 非法写法
DELIMITER //
DROP TRIGGER IF EXISTS before_credit_account_delete;
CREATE TRIGGER before_credit_account_delete
BEFORE DELETE ON credit_account
FOR EACH ROW
BEGIN
    DECLARE v_remaining_total DECIMAL(15, 2) DEFAULT 0.00;

    -- 只做校验：统计账户下所有贷款剩余总额
    SELECT IFNULL(SUM(get_remaining_loan_amount(loan_id)), 0) 
    INTO v_remaining_total 
    FROM loan 
    WHERE account_id = OLD.account_id;

    -- 有未结清贷款，直接拦截销户
    IF v_remaining_total > 0.00 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = '销户失败：该信用账户下尚有未还清的贷款，请先结清全部贷款！';
    END IF;

    -- 校验账户余额
    IF old.balance != 0 THEN
        IF old.balance > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '销户失败：该信用账户内仍有预存款（余额），请先取回资金！';
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '该信用账户尚有透支欠款未还清，请先还款！';
        END IF;
    END IF;

    UPDATE Bank SET asset = asset - old.balance WHERE bank_name = old.bank_name;
END ;
//
DELIMITER ;