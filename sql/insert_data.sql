use banksystem;

-- ===== 1. 河南核心地方银行数据 =====
insert into Bank values('中原银行', '河南 郑州', 1200000000.00, '/media/images/中原银行.png');
insert into Bank values('郑州银行', '河南 郑州', 950000000.00, '/media/images/郑州银行.png');
insert into Bank values('洛阳银行', '河南 洛阳', 450000000.00, '/media/images/洛阳银行.png');
insert into Bank values('河南农商银行', '河南 新乡', 320000000.00, '/media/images/河南农商银行.png');
insert into Bank values('平顶山银行', '河南 平顶山', 290000000.00, '/media/images/平顶山银行.png');


-- ===== 2. 部门数据（5家银行 × 14个部门 = 70个部门）=====

-- [1] 中原银行 (中原崛起，前缀 ZY)
insert into department values('ZY001', '中原银行', '总行', '总行');
insert into department values('ZY002', '中原银行', '财务部', '财务部');
insert into department values('ZY003', '中原银行', '人事部', '人事部');
insert into department values('ZY004', '中原银行', '业务部', '业务部');
insert into department values('ZY005', '中原银行', '客户服务部', '客户服务部');
insert into department values('ZY006', '中原银行', '信贷部', '信贷部');
insert into department values('ZY007', '中原银行', '贷款部', '贷款部');
insert into department values('ZY008', '中原银行', '存款部', '存款部');
insert into department values('ZY009', '中原银行', '风险管理部', '风险管理部');
insert into department values('ZY010', '中原银行', '资产管理部', '资产管理部');
insert into department values('ZY011', '中原银行', '信息技术部', '信息技术部');
insert into department values('ZY012', '中原银行', '审计部', '审计部');
insert into department values('ZY013', '中原银行', '法律部', '法律部');
insert into department values('ZY014', '中原银行', '人力资源部', '人力资源部');

-- [2] 郑州银行 (商城金融，前缀 ZZ)
insert into department values('ZZ001', '郑州银行', '总行', '总行');
insert into department values('ZZ002', '郑州银行', '财务部', '财务部');
insert into department values('ZZ003', '郑州银行', '人事部', '人事部');
insert into department values('ZZ004', '郑州银行', '业务部', '业务部');
insert into department values('ZZ005', '郑州银行', '客户服务部', '客户服务部');
insert into department values('ZZ006', '郑州银行', '信贷部', '信贷部');
insert into department values('ZZ007', '郑州银行', '贷款部', '贷款部');
insert into department values('ZZ008', '郑州银行', '存款部', '存款部');
insert into department values('ZZ009', '郑州银行', '风险管理部', '风险管理部');
insert into department values('ZZ010', '郑州银行', '资产管理部', '资产管理部');
insert into department values('ZZ011', '郑州银行', '信息技术部', '信息技术部');
insert into department values('ZZ012', '郑州银行', '审计部', '审计部');
insert into department values('ZZ013', '郑州银行', '法律部', '法律部');
insert into department values('ZZ014', '郑州银行', '人力资源部', '人力资源部');

-- [3] 洛阳银行 (神都农商，前缀 LY)
insert into department values('LY001', '洛阳银行', '总行', '总行');
insert into department values('LY002', '洛阳银行', '财务部', '财务部');
insert into department values('LY003', '洛阳银行', '人事部', '人事部');
insert into department values('LY004', '洛阳银行', '业务部', '业务部');
insert into department values('LY005', '洛阳银行', '客户服务部', '客户服务部');
insert into department values('LY006', '洛阳银行', '信贷部', '信贷部');
insert into department values('LY007', '洛阳银行', '贷款部', '贷款部');
insert into department values('LY008', '洛阳银行', '存款部', '存款部');
insert into department values('LY009', '洛阳银行', '风险管理部', '风险管理部');
insert into department values('LY010', '洛阳银行', '资产管理部', '资产管理部');
insert into department values('LY011', '洛阳银行', '信息技术部', '信息技术部');
insert into department values('LY012', '洛阳银行', '审计部', '审计部');
insert into department values('LY013', '洛阳银行', '法律部', '法律部');
insert into department values('LY014', '洛阳银行', '人力资源部', '人力资源部');

-- [4] 河南农商银行 (牧野农商，前缀 XX)
insert into department values('XX001', '河南农商银行', '总行', '总行');
insert into department values('XX002', '河南农商银行', '财务部', '财务部');
insert into department values('XX003', '河南农商银行', '人事部', '人事部');
insert into department values('XX004', '河南农商银行', '业务部', '业务部');
insert into department values('XX005', '河南农商银行', '客户服务部', '客户服务部');
insert into department values('XX006', '河南农商银行', '信贷部', '信贷部');
insert into department values('XX007', '河南农商银行', '贷款部', '贷款部');
insert into department values('XX008', '河南农商银行', '存款部', '存款部');
insert into department values('XX009', '河南农商银行', '风险管理部', '风险管理部');
insert into department values('XX010', '河南农商银行', '资产管理部', '资产管理部');
insert into department values('XX011', '河南农商银行', '信息技术部', '信息技术部');
insert into department values('XX012', '河南农商银行', '审计部', '审计部');
insert into department values('XX013', '河南农商银行', '法律部', '法律部');
insert into department values('XX014', '河南农商银行', '人力资源部', '人力资源部');

-- [5] 平顶山银行 (莲城农商，前缀 XC)
insert into department values('XC001', '平顶山银行', '总行', '总行');
insert into department values('XC002', '平顶山银行', '财务部', '财务部');
insert into department values('XC003', '平顶山银行', '人事部', '人事部');
insert into department values('XC004', '平顶山银行', '业务部', '业务部');
insert into department values('XC005', '平顶山银行', '客户服务部', '客户服务部');
insert into department values('XC006', '平顶山银行', '信贷部', '信贷部');
insert into department values('XC007', '平顶山银行', '贷款部', '贷款部');
insert into department values('XC008', '平顶山银行', '存款部', '存款部');
insert into department values('XC009', '平顶山银行', '风险管理部', '风险管理部');
insert into department values('XC010', '平顶山银行', '资产管理部', '资产管理部');
insert into department values('XC011', '平顶山银行', '信息技术部', '信息技术部');
insert into department values('XC012', '平顶山银行', '审计部', '审计部');
insert into department values('XC013', '平顶山银行', '法律部', '法律部');
insert into department values('XC014', '平顶山银行', '人力资源部', '人力资源部');


-- ===== 3. 员工数据（工号E101起，身份证地缘契合河南41开头）=====
-- 中原银行员工
insert into employee values('E101', 'ZY001', '410101198803151234', '史国庆', '男', '13523450001', '郑州市金水区', '2014-05-12');
insert into employee values('E102', 'ZY006', '410104199211042345', '曹艳丽', '女', '13523450002', '郑州市管城区', '2017-08-21');
insert into employee values('E103', 'ZY011', '410105199507183456', '郭创新', '男', '13523450003', '郑州市郑东新区', '2020-07-01');

-- 郑州银行员工
insert into employee values('E104', 'ZZ001', '410102198601224567', '刘东升', '男', '13613810001', '郑州市中原区', '2012-03-10');
insert into employee values('E105', 'ZZ005', '410103199109145678', '马秀琴', '女', '13613810002', '郑州市二七区', '2016-10-15');
insert into employee values('E106', 'ZZ007', '410108199304306789', '薛金龙', '男', '13613810003', '郑州市惠济区', '2019-01-08');

-- 洛阳银行员工
insert into employee values('E107', 'LY001', '410302198905017890', '张牡丹', '女', '13703790001', '洛阳市西工区', '2013-07-16');
insert into employee values('E108', 'LY006', '410303199412258901', '王建洛', '男', '13703790002', '洛阳市涧西区', '2018-04-11');
insert into employee values('E109', 'LY008', '410305199008139012', '李向阳', '男', '13703790003', '洛阳市老城区', '2015-11-20');

-- 河南农商银行员工
insert into employee values('E110', 'XX001', '410702198706020123', '赵卫国', '男', '13837310001', '新乡市红旗区', '2011-09-05');
insert into employee values('E111', 'XX004', '410703199302171234', '孙晓晓', '女', '13837310002', '新乡市卫滨区', '2018-06-30');
insert into employee values('E112', 'XX007', '410711199610282345', '田丰收', '男', '13837310003', '新乡市牧野区', '2021-02-14');

-- 平顶山银行员工
insert into employee values('E113', 'XC001', '411002199004123456', '魏三国', '男', '13903740001', '平顶山市魏都区', '2015-03-25');
insert into employee values('E114', 'XC005', '411023199207054567', '许莲织', '女', '13903740002', '平顶山市建安区', '2017-12-01');
insert into employee values('E115', 'XC009', '411081198910195678', '韩忠义', '男', '13903740003', '平顶山市禹州市', '2013-08-18');


-- ===== 4. 客户数据（共25名客户，深度契合河南本土人文特征）=====
insert into client values('C101', '410101199002161111', '郑新才', '男', '郑州市金水区', '15038110001', 'zhengxc@email.com', '郑母', '15038110101', 'zhengmu@email.com', '母子');
insert into client values('C102', '410104199307222222', '胡曼曼', '女', '郑州市管城区', '15038110002', 'humm@email.com', '胡父', '15038110102', 'hufu@email.com', '父女');
insert into client values('C103', '410302199105123333', '白乐天', '男', '洛阳市洛龙区', '15137910001', 'bai@email.com', '白妻', '15137910101', 'baiqi@email.com', '夫妻');
insert into client values('C104', '410305198908244444', '常香玉', '女', '洛阳市中州路', '15137910002', 'changxy@email.com', '常父', '15137910102', 'changfu@email.com', '父女');
insert into client values('C105', '410702198809015555', '原太行', '男', '新乡市辉县市', '15237310001', 'yuanth@email.com', '原妻', '15237310101', 'yuanqi@email.com', '夫妻');
insert into client values('C106', '410703199511126666', '岳飞扬', '男', '新乡市汤阴路', '15237310002', 'yuefy@email.com', '岳母', '15237310102', 'yuemu@email.com', '母子');
insert into client values('C107', '411002199203147777', '曹操练', '男', '平顶山市魏都区', '15517310001', 'caocl@email.com', '曹妻', '15517310101', 'caoqi@email.com', '夫妻');
insert into client values('C108', '411023198812258888', '甄宓儿', '女', '平顶山市钧瓷路', '15517310002', 'zhenme@email.com', '甄夫', '15517310102', 'zhenfu@email.com', '夫妻');
insert into client values('C109', '410202199001019999', '包正青', '男', '开封市鼓楼区', '15603780001', 'baozq@email.com', '包母', '15603780101', 'baomu@email.com', '母子');
insert into client values('C110', '410402199106180000', '鹰击长', '男', '平顶山市新华区', '15703750001', 'yingjc@email.com', '鹰父', '15703750102', 'yingfu@email.com', '父女');
insert into client values('C111', '410502199204161111', '商殷鼎', '男', '安阳市殷都区', '15803720001', 'shangyd@email.com', '商母', '15803720101', 'shangmu@email.com', '母子');
insert into client values('C112', '410602199308272222', '淇水清', '女', '鹤壁市淇滨区', '15903920001', 'qisq@email.com', '淇夫', '15903920102', 'qifu@email.com', '夫妻');
insert into client values('C113', '410802199109183333', '司马懿', '男', '焦作市温县', '13017510001', 'simay@email.com', '司马妻', '13017510101', 'simaqi@email.com', '夫妻');
insert into client values('C114', '410902199302254444', '张帝喾', '男', '濮阳市华龙区', '13103930001', 'zhangdk@email.com', '张母', '13103930102', 'zhangmu@email.com', '母子');
insert into client values('C115', '411102199005115555', '贾湖笛', '女', '漯河市舞阳县', '13203950001', 'jiahud@email.com', '贾父', '13203950102', 'jiafu@email.com', '父女');
insert into client values('C116', '411202199211226666', '仰韶陶', '男', '三门峡市渑池县', '13303980001', 'yangst@email.com', '仰父', '13303980102', 'yangfu@email.com', '父女');
insert into client values('C117', '411302199107037777', '诸葛庐', '男', '南阳市卧龙区', '13403770001', 'zhugel@email.com', '诸葛妻', '13403770101', 'zhugeqi@email.com', '夫妻');
insert into client values('C118', '411402199308158888', '木兰归', '女', '商丘市虞城县', '13503700001', 'mulang@email.com', '木兰母', '13503701012', 'mulanmu@email.com', '母女');
insert into client values('C119', '411502198705209999', '红安居', '男', '信阳市新县', '13603760001', 'honganju@email.com', '红妻', '13603760103', 'hongqi@email.com', '夫妻');
insert into client values('C120', '411602199509010000', '老子出', '男', '周口市鹿邑县', '13703940001', 'laozic@email.com', '老子母', '13703940103', 'laozimu@email.com', '母子');
insert into client values('C121', '411702199403021111', '天中客', '男', '驻马店市驿城区', '13803960001', 'tianzk@email.com', '天中妻', '13803960101', 'tianzqi@email.com', '夫妻');
insert into client values('C122', '419001199206122222', '愚公移', '男', '济源市王屋山', '13903910001', 'yugongy@email.com', '愚公妻', '13903910101', 'yuqi@email.com', '夫妻');
insert into client values('C123', '410105198604053333', '刘新郑', '男', '郑州市新郑市', '18503710001', 'liuxz@email.com', '刘母', '18503710101', 'liumu@email.com', '母子');
insert into client values('C124', '410181199312124444', '杜诗圣', '男', '郑州市巩义市', '18603710002', 'duss@email.com', '杜妻', '18603710102', 'duqi@email.com', '夫妻');
insert into client values('C125', '410322199110055555', '关圣帝', '男', '洛阳市新安县', '18703790005', 'guansd@email.com', '关母', '18703790105', 'guanmu@email.com', '母子');


-- ===== 5. 储蓄账户数据（账号SA101起）=====
insert into saving_account values('SA101', '中原银行', 'C101', 120000.00, '2021-03-15', 0.0325);
insert into saving_account values('SA102', '中原银行', 'C102', 45000.00, '2022-06-20', 0.0310);
insert into saving_account values('SA103', '郑州银行', 'C103', 280000.00, '2020-11-10', 0.0345);
insert into saving_account values('SA104', '郑州银行', 'C104', 65000.00, '2022-01-08', 0.0310);
insert into saving_account values('SA105', '洛阳银行', 'C105', 90000.00, '2021-07-22', 0.0360);
insert into saving_account values('SA106', '洛阳银行', 'C106', 35000.00, '2022-09-14', 0.0335);
insert into saving_account values('SA107', '河南农商银行', 'C107', 140000.00, '2021-04-30', 0.0360);
insert into saving_account values('SA108', '河南农商银行', 'C108', 75000.00, '2023-03-18', 0.0335);
insert into saving_account values('SA109', '平顶山银行', 'C109', 185000.00, '2020-08-25', 0.0365);
insert into saving_account values('SA110', '平顶山银行', 'C110', 25000.00, '2022-12-05', 0.0335);
insert into saving_account values('SA111', '中原银行', 'C111', 320000.00, '2020-02-14', 0.0350);
insert into saving_account values('SA112', '郑州银行', 'C112', 98000.00, '2022-05-09', 0.0325);
insert into saving_account values('SA113', '洛阳银行', 'C113', 52000.00, '2022-03-28', 0.0335);
insert into saving_account values('SA114', '河南农商银行', 'C114', 118000.00, '2021-10-11', 0.0360);
insert into saving_account values('SA115', '平顶山银行', 'C115', 63000.00, '2022-07-16', 0.0335);
insert into saving_account values('SA116', '中原银行', 'C116', 87000.00, '2021-01-22', 0.0325);
insert into saving_account values('SA117', '郑州银行', 'C117', 215000.00, '2020-05-30', 0.0345);
insert into saving_account values('SA118', '洛阳银行', 'C118', 43000.00, '2023-04-03', 0.0335);
insert into saving_account values('SA119', '河南农商银行', 'C119', 390000.00, '2019-12-20', 0.0385);
insert into saving_account values('SA120', '平顶山银行', 'C120', 55000.00, '2023-02-14', 0.0335);


-- ===== 6. 信用账户数据（卡号CA101起）=====
insert into credit_account values('CA101', '中原银行', 'C101', 1200.00, '2021-03-15', 30000.00);
insert into credit_account values('CA102', '郑州银行', 'C103', 4500.00, '2020-11-10', 50000.00);
insert into credit_account values('CA103', '洛阳银行', 'C105', 800.00, '2021-07-22', 20000.00);
insert into credit_account values('CA104', '河南农商银行', 'C107', 9000.00, '2021-04-30', 40000.00);
insert into credit_account values('CA105', '平顶山银行', 'C109', 3200.00, '2020-08-25', 25000.00);
insert into credit_account values('CA106', '中原银行', 'C111', 15000.00, '2020-02-14', 100000.00);
insert into credit_account values('CA107', '郑州银行', 'C112', 2300.00, '2022-05-09', 30000.00);
insert into credit_account values('CA108', '洛阳银行', 'C113', 0.00, '2022-03-28', 15000.00);
insert into credit_account values('CA109', '河南农商银行', 'C114', 6800.00, '2021-10-11', 35000.00);
insert into credit_account values('CA110', '平顶山银行', 'C119', 11000.00, '2019-12-20', 80000.00);


-- ===== 7. 贷款数据（已适配 schema，补齐 ount_id 外键）=====
-- 注意：确保每个 ount_id 在 credit_account 中对应正确的 client_id 和 bank_name
-- 确保在执行前已插入对应的客户与信用账户数据

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L101', 'C101', '中原银行', 'CA101', 25000.00, 0.0415, '2022-01-10');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L102', 'C103', '郑州银行', 'CA102', 45000.00, 0.0395, '2021-06-15');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L103', 'C105', '洛阳银行', 'CA103', 18000.00, 0.0435, '2022-03-20');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L104', 'C107', '河南农商银行', 'CA104', 35000.00, 0.0450, '2022-02-08');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L105', 'C109', '平顶山银行', 'CA105', 20000.00, 0.0435, '2021-11-25');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L106', 'C111', '中原银行', 'CA106', 90000.00, 0.0395, '2021-08-30');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L107', 'C112', '郑州银行', 'CA107', 25000.00, 0.0420, '2023-04-12');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L108', 'C114', '河南农商银行', 'CA109', 30000.00, 0.0435, '2022-09-18');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L109', 'C113', '洛阳银行', 'CA108', 10000.00, 0.0395, '2021-07-22');

insert into loan(loan_id, client_id, bank_name, account_id, loan_money, loan_rate, loan_date) 
values('L110', 'C119', '平顶山银行', 'CA110', 75000.00, 0.0415, '2020-05-15');
-- ===== 8. 还款记录数据（按缩减后的贷款总额同比例缩小流水金额）=====
-- L101 (中原银行) 连续还款流水，总贷款 25000，已还 15000
insert into pay_loan(pay_money, pay_date, loan_id) values(5000.00, '2022-04-10', 'L101');
insert into pay_loan(pay_money, pay_date, loan_id) values(5000.00, '2022-07-10', 'L101');
insert into pay_loan(pay_money, pay_date, loan_id) values(5000.00, '2022-10-10', 'L101');

-- L102 (郑州银行) 季付流水，总贷款 45000，已还 40000
insert into pay_loan(pay_money, pay_date, loan_id) values(10000.00, '2021-09-15', 'L102');
insert into pay_loan(pay_money, pay_date, loan_id) values(10000.00, '2021-12-15', 'L102');
insert into pay_loan(pay_money, pay_date, loan_id) values(10000.00, '2022-03-15', 'L102');
insert into pay_loan(pay_money, pay_date, loan_id) values(10000.00, '2022-06-15', 'L102');

-- L103 (洛阳银行) 联合放款收回，总贷款 18000，已还 10000
insert into pay_loan(pay_money, pay_date, loan_id) values(5000.00, '2022-06-20', 'L103');
insert into pay_loan(pay_money, pay_date, loan_id) values(5000.00, '2022-09-20', 'L103');

-- L105 (平顶山银行)，总贷款 20000，已还 16000
insert into pay_loan(pay_money, pay_date, loan_id) values(8000.00, '2022-02-25', 'L105');
insert into pay_loan(pay_money, pay_date, loan_id) values(8000.00, '2022-05-25', 'L105');

-- L106 (中原银行大单)，总贷款 90000，已还 60000
insert into pay_loan(pay_money, pay_date, loan_id) values(30000.00, '2022-02-28', 'L106');
insert into pay_loan(pay_money, pay_date, loan_id) values(30000.00, '2022-08-30', 'L106');

-- L110 (平顶山银行长期单)，总贷款 75000，已还 60000
insert into pay_loan(pay_money, pay_date, loan_id) values(20000.00, '2020-11-15', 'L110');
insert into pay_loan(pay_money, pay_date, loan_id) values(20000.00, '2021-05-15', 'L110');
insert into pay_loan(pay_money, pay_date, loan_id) values(20000.00, '2021-11-15', 'L110');