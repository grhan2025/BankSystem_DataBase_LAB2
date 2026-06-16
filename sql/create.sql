drop database if exists banksystem;
create database banksystem;


use banksystem;

drop table if exists pay_loan;
drop table if exists loan;
drop table if exists credit_account;
drop table if exists saving_account;
drop table if exists employee;
drop table if exists department;
drop table if exists client;
drop table if exists Bank;


create table Bank
(
    bank_name   varchar(30) primary key,
    location    varchar(30) not null,
    asset       decimal(15, 2) not null CHECK (asset >= 0),
    image       VARCHAR(255)
);

create table department
(
    department_id   varchar(18) primary key,
    bank_name       varchar(30) not null,
    department_name varchar(30) not null,
    department_type varchar(30) not null,
    foreign key (bank_name) references Bank(bank_name) ON DELETE CASCADE
);

create table employee
(
    employee_id     varchar(18) primary key,
    department_id   varchar(18) not null,
    id              varchar(18) not null,
    name            varchar(30) not null,
    sex             varchar(1)  not null,
    phone           varchar(30) not null,
    address         varchar(30) not null,
    start_work_date date    not null,
    foreign key(department_id)  references  department(department_id) ON DELETE CASCADE
);

create table client 
(
    client_id   varchar(18) primary key,
    id          varchar(18) not null,
    name        varchar(30) not null,
    sex         varchar(1)  not null,
    address     varchar(30) not null,
    phone       varchar(30) not null,
    email       varchar(30) not null,
    contact_name    varchar(30) not null,
    contact_phone   varchar(20) not null,
    contact_email   varchar(30) not null,
    contact_relation    varchar(20) not null
);

create table credit_account(
    account_id char(18) primary key,
    bank_name  varchar(30) not null,
    client_id  varchar(18) not null,
    balance    decimal(15, 2) not null CHECK (balance >= 0),
    open_date  date not null,
    overdraft  decimal(15, 2) not null CHECK (overdraft >= 0),
    foreign key (bank_name) references Bank(bank_name) ON DELETE CASCADE,
    foreign key (client_id) references client(client_id) ON DELETE CASCADE
);

create table saving_account(
    account_id char(18) primary key,
    bank_name  varchar(30) not null,
    client_id  varchar(18) not null,
    balance    decimal(15, 2) not null CHECK (balance >= 0),
    open_date  date not null,
    rate       decimal(5, 4) not null CHECK (rate >= 0),
    foreign key (bank_name) references Bank(bank_name) ON DELETE CASCADE,
    foreign key (client_id) references client(client_id) ON DELETE CASCADE
);

create table loan
(
    loan_id         varchar(32) primary key,
    client_id       varchar(18) not null,
    bank_name       varchar(30) not null,
    account_id      char(18)    not null,
    loan_money      decimal(15, 2) not null CHECK (loan_money > 0),
    loan_rate       decimal(5, 4) not null CHECK (loan_rate >= 0),
    loan_date       date    not null,
    accrued_interest decimal(15, 2) not null DEFAULT 0.00,  -- 新增：累计应计利息
    last_interest_date date DEFAULT NULL,                   -- 新增：上次结息日期
    foreign key(client_id)  references  client(client_id) ON DELETE CASCADE,
    foreign key(bank_name)  references  Bank(bank_name) ON DELETE CASCADE,
    foreign key(account_id) references  credit_account(account_id) ON DELETE CASCADE
);
create table pay_loan
(
    pay_id      integer not null auto_increment,
    pay_money   decimal(15, 2) not null,
    pay_date    date    not null,
    loan_id     varchar(32) not null,
    primary key (pay_id, loan_id),
    foreign key (loan_id) references loan(loan_id) ON DELETE CASCADE
);