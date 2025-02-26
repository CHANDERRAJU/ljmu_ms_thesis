-- table1
CREATE TABLE s_admissions_new as
select * from s_admissions where sepsis_flag = 'Yes' and drg_type='HCFA' and diabetic_flag="Yes";
