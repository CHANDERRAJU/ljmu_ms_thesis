/* use case 2 : compute difference between dischtime and admittime to compute LOS.*/
ALTER TABLE sepsis_admissions
ADD COLUMN LOS decimal;  sepsis_admissions-- or use `DECIMAL` if you need a more precise value (e.g., for hours)

UPDATE sepsis_admissions
SET LOS = DATEDIFF(dischtime, admittime);

/* use case 3: compute difference between edregtime and edouttime to compute ED Hours */
ALTER TABLE sepsis_admissions
ADD COLUMN edhours decimal;  -- or use `DECIMAL` if you need a more precise value (e.g., for hours)
UPDATE sepsis_admissions
SET edhours = TIMESTAMPDIFF(HOUR, edregtime, edouttime); 

/* use case 4: compute count of HADM IDs by patient to determine total unique admissions and admissions by admission type, cumulative LOS days, cumulative ER visits, cumulative ER hours. */
CREATE VIEW PATIENT_COUNT AS
SELECT 
    subject_id, 
    COUNT(DISTINCT hadm_id) AS admission_count, 
    SUM(LOS) AS cum_LOS, 
    SUM(edhours) AS ED_Hours,
    COUNT(DISTINCT CASE WHEN edregtime IS NOT NULL THEN hadm_id END) AS ED_visit_count
FROM sepsis_admissions
GROUP BY subject_id, admission_type;

/* use case 5 profile patients by admission type ,admission location and discharge location  */
CREATE VIEW patientprofileby_admission_type as
select admission_type, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount from sepsis_admissions
group by admission_type

CREATE VIEW patientprofileby_admission_discharge_location_deathcount as
select admission_type, admission_location, discharge_location, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN hospital_expire_flag = 1 THEN hadm_id END) AS DEATH_COUNT  from sepsis_admissions
group by admission_type, admission_location, discharge_location

/* use case 6 : profile patients based on race based on subject id and hadm ID */

CREATE VIEW patientprofileby_race as
select race, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN hospital_expire_flag = 1 THEN hadm_id END) AS DEATH_COUNT  from sepsis_admissions
group by race

CREATE VIEW patientprofileby_maritalstatus as
select marital_status, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN hospital_expire_flag = 1 THEN hadm_id END) AS DEATH_COUNT  from sepsis_admissions
group by marital_status

CREATE VIEW patientprofileby_insurance as
select insurance, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN hospital_expire_flag = 1 THEN hadm_id END) AS DEATH_COUNT  from sepsis_admissions
group by insurance


select s2.gender, s2.anchor_age, count(distinct s1.subject_id) as patientcount, count(distinct s1.hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN s1.hospital_expire_flag = 1 THEN s1.hadm_id END) AS DEATH_COUNT  from sepsis_admissions as s1
LEFT JOIN sepsis_patients as s2
ON s1.subject_id=s2.subject_id
group by gender, anchor_age

SELECT 
    s2.gender,
    CASE 
        WHEN s2.anchor_age BETWEEN 0 AND 18 THEN '0-18'
        WHEN s2.anchor_age BETWEEN 19 AND 35 THEN '19-35'
        WHEN s2.anchor_age BETWEEN 36 AND 50 THEN '36-50'
        WHEN s2.anchor_age BETWEEN 51 AND 65 THEN '51-65'
        WHEN s2.anchor_age BETWEEN 66 AND 80 THEN '66-80'
        WHEN s2.anchor_age > 80 THEN '81+'
        ELSE 'Unknown'
    END AS age_category,
    COUNT(DISTINCT s1.subject_id) AS patientcount, 
    COUNT(DISTINCT s1.hadm_id) AS visitcount,
    COUNT(DISTINCT CASE WHEN s1.hospital_expire_flag = 1 THEN s1.hadm_id END) AS DEATH_COUNT  
FROM 
    sepsis_admissions AS s1
LEFT JOIN 
    sepsis_patients AS s2 ON s1.subject_id = s2.subject_id
GROUP BY 
    s2.gender, 
    age_category;

SELECT 
    s2.gender,
    CASE 
        WHEN s2.anchor_age BETWEEN 0 AND 18 THEN '0-18'
        WHEN s2.anchor_age BETWEEN 19 AND 35 THEN '19-35'
        WHEN s2.anchor_age BETWEEN 36 AND 50 THEN '36-50'
        WHEN s2.anchor_age BETWEEN 51 AND 65 THEN '51-65'
        WHEN s2.anchor_age BETWEEN 66 AND 80 THEN '66-80'
        WHEN s2.anchor_age > 80 THEN '81+'
        ELSE 'Unknown'
    END AS age_category,
    COUNT(DISTINCT s1.subject_id) AS patientcount, 
    COUNT(DISTINCT s1.hadm_id) AS visitcount,
    COUNT(DISTINCT CASE WHEN s1.hospital_expire_flag = 1 THEN s1.hadm_id END) AS DEATH_COUNT,
    COUNT(DISTINCT CASE WHEN s3.sepsis_flag = 'yes' THEN s1.hadm_id END) AS sepsis_flag_yes_count,
    COUNT(DISTINCT CASE WHEN s3.sepsis_flag = 'no' THEN s1.hadm_id END) AS sepsis_flag_no_count
FROM 
    sepsis_admissions AS s1
LEFT JOIN 
    sepsis_patients AS s2 ON s1.subject_id = s2.subject_id
LEFT JOIN 
    sepsis_admission_withinline_dx AS s3 ON s1.hadm_id = s3.hadm_id
GROUP BY 
    s2.gender, 
    age_category;

/* Use case 7 */
CREATE VIEW PATIENT_PROFILE_BY_AGE_GENDER AS
SELECT 
	s2.gender,
	CASE 
		WHEN s2.anchor_age BETWEEN 0 AND 18 THEN '0-18'
		WHEN s2.anchor_age BETWEEN 19 AND 35 THEN '19-35'
		WHEN s2.anchor_age BETWEEN 36 AND 50 THEN '36-50'
		WHEN s2.anchor_age BETWEEN 51 AND 65 THEN '51-65'
		WHEN s2.anchor_age BETWEEN 66 AND 80 THEN '66-80'
		WHEN s2.anchor_age > 80 THEN '81+'
		ELSE 'Unknown'
	END AS age_category,
	COUNT(DISTINCT s1.subject_id) AS patientcount, 
	COUNT(DISTINCT s1.hadm_id) AS visitcount,
	COUNT(DISTINCT CASE WHEN s1.hospital_expire_flag = 1 THEN s1.hadm_id END) AS DEATH_COUNT,
	
	-- Count sepsis_flag_yes if the hadm_id exists in the sepsis_patient_list
	COUNT(DISTINCT CASE WHEN s3.hadm_id IS NOT NULL THEN s1.hadm_id END) AS sepsis_flag_yes_count,
	
	-- Count sepsis_flag_no if the hadm_id does not exist in the sepsis_patient_list
	COUNT(DISTINCT CASE WHEN s3.hadm_id IS NULL THEN s1.hadm_id END) AS sepsis_flag_no_count
FROM 
	sepsis_admissions AS s1
LEFT JOIN 
	sepsis_patients AS s2 ON s1.subject_id = s2.subject_id
LEFT JOIN 
	sespsis_patient_list AS s3 ON s1.hadm_id = s3.hadm_id  -- Check if hadm_id exists in sepsis_patient_list
GROUP BY 
	s2.gender;
	
/* end */

/* Use case 7.a */
CREATE VIEW PATIENT_PROFILE_BY_AGE AS
SELECT 
	CASE 
		WHEN s2.anchor_age BETWEEN 0 AND 18 THEN '0-18'
		WHEN s2.anchor_age BETWEEN 19 AND 35 THEN '19-35'
		WHEN s2.anchor_age BETWEEN 36 AND 50 THEN '36-50'
		WHEN s2.anchor_age BETWEEN 51 AND 65 THEN '51-65'
		WHEN s2.anchor_age BETWEEN 66 AND 80 THEN '66-80'
		WHEN s2.anchor_age > 80 THEN '81+'
		ELSE 'Unknown'
	END AS age_category,
	COUNT(DISTINCT s1.subject_id) AS patientcount, 
	COUNT(DISTINCT s1.hadm_id) AS visitcount,
	COUNT(DISTINCT CASE WHEN s1.hospital_expire_flag = 1 THEN s1.hadm_id END) AS DEATH_COUNT,
	
	-- Count sepsis_flag_yes if the hadm_id exists in the sepsis_patient_list
	COUNT(DISTINCT CASE WHEN s3.hadm_id IS NOT NULL THEN s1.hadm_id END) AS sepsis_flag_yes_count,
	
	-- Count sepsis_flag_no if the hadm_id does not exist in the sepsis_patient_list
	COUNT(DISTINCT CASE WHEN s3.hadm_id IS NULL THEN s1.hadm_id END) AS sepsis_flag_no_count
FROM 
	sepsis_admissions AS s1
LEFT JOIN 
	sepsis_patients AS s2 ON s1.subject_id = s2.subject_id
LEFT JOIN 
	sespsis_patient_list AS s3 ON s1.hadm_id = s3.hadm_id  -- Check if hadm_id exists in sepsis_patient_list
GROUP BY 
	age_category;
/* end */

/* Use case 7.a */
CREATE VIEW PATIENT_PROFILE_BY_GENDER AS
SELECT 
	s2.gender,
	COUNT(DISTINCT s1.subject_id) AS patientcount, 
	COUNT(DISTINCT s1.hadm_id) AS visitcount,
	COUNT(DISTINCT CASE WHEN s1.hospital_expire_flag = 1 THEN s1.hadm_id END) AS DEATH_COUNT,
	-- Count sepsis_flag_yes if the hadm_id exists in the sepsis_patient_list
	COUNT(DISTINCT CASE WHEN s3.hadm_id IS NOT NULL THEN s1.hadm_id END) AS sepsis_flag_yes_count,
	-- Count sepsis_flag_no if the hadm_id does not exist in the sepsis_patient_list
	COUNT(DISTINCT CASE WHEN s3.hadm_id IS NULL THEN s1.hadm_id END) AS sepsis_flag_no_count
FROM 
	sepsis_admissions AS s1
LEFT JOIN 
	sepsis_patients AS s2 ON s1.subject_id = s2.subject_id
LEFT JOIN 
	sespsis_patient_list AS s3 ON s1.hadm_id = s3.hadm_id  -- Check if hadm_id exists in sepsis_patient_list
GROUP BY 
	s2.gender;
/* end */




/*  SEPSIS_DIAGNOSIS_IN_LINE */
CREATE TABLE SEPSIS_DIAGNOSIS_IN_LINE AS 
SELECT 
    s.hadm_id, s.subject_id,
    -- Add other specific columns here as needed
    -- For diagnosis 1 (seq_num = 1)
    MAX(CASE WHEN dx.seq_num = 1 THEN dx.icd_code END) AS dx_1_code,
    MAX(CASE WHEN dx.seq_num = 1 THEN dx.icd_version END) AS dx_1_version,
    MAX(CASE WHEN dx.seq_num = 1 THEN dx.long_title END) AS dx_1_title,
    
    -- For diagnosis 2 (seq_num = 2)
    MAX(CASE WHEN dx.seq_num = 2 THEN dx.icd_code END) AS dx_2_code,
    MAX(CASE WHEN dx.seq_num = 2 THEN dx.icd_version END) AS dx_2_version,
    MAX(CASE WHEN dx.seq_num = 2 THEN dx.long_title END) AS dx_2_title,

    -- For diagnosis 3 (seq_num = 3)
    MAX(CASE WHEN dx.seq_num = 3 THEN dx.icd_code END) AS dx_3_code,
    MAX(CASE WHEN dx.seq_num = 3 THEN dx.icd_version END) AS dx_3_version,
    MAX(CASE WHEN dx.seq_num = 3 THEN dx.long_title END) AS dx_3_title,
    -- For diagnosis 4 (seq_num = 4)
    MAX(CASE WHEN dx.seq_num = 4 THEN dx.icd_code END) AS dx_4_code,
    MAX(CASE WHEN dx.seq_num = 4 THEN dx.icd_version END) AS dx_4_version,
    MAX(CASE WHEN dx.seq_num = 4 THEN dx.long_title END) AS dx_4_title,
    -- For diagnosis 5 (seq_num = 5)
    MAX(CASE WHEN dx.seq_num = 5 THEN dx.icd_code END) AS dx_5_code,
    MAX(CASE WHEN dx.seq_num = 5 THEN dx.icd_version END) AS dx_5_version,
    MAX(CASE WHEN dx.seq_num = 5 THEN dx.long_title END) AS dx_5_title,
    -- For diagnosis 6 (seq_num = 6)
    MAX(CASE WHEN dx.seq_num = 6 THEN dx.icd_code END) AS dx_6_code,
    MAX(CASE WHEN dx.seq_num = 6 THEN dx.icd_version END) AS dx_6_version,
    MAX(CASE WHEN dx.seq_num = 6 THEN dx.long_title END) AS dx_6_title,
    -- For diagnosis 7 (seq_num = 7)
    MAX(CASE WHEN dx.seq_num = 7 THEN dx.icd_code END) AS dx_7_code,
    MAX(CASE WHEN dx.seq_num = 7 THEN dx.icd_version END) AS dx_7_version,
    MAX(CASE WHEN dx.seq_num = 7 THEN dx.long_title END) AS dx_7_title,
    -- For diagnosis 8 (seq_num = 8)
    MAX(CASE WHEN dx.seq_num = 8 THEN dx.icd_code END) AS dx_8_code,
    MAX(CASE WHEN dx.seq_num = 8 THEN dx.icd_version END) AS dx_8_version,
    MAX(CASE WHEN dx.seq_num = 8 THEN dx.long_title END) AS dx_8_title,
    -- For diagnosis 9 (seq_num = 9)
    MAX(CASE WHEN dx.seq_num = 9 THEN dx.icd_code END) AS dx_9_code,
    MAX(CASE WHEN dx.seq_num = 9 THEN dx.icd_version END) AS dx_9_version,
    MAX(CASE WHEN dx.seq_num = 9 THEN dx.long_title END) AS dx_9_title,
    -- For diagnosis 10 (seq_num = 10)
    MAX(CASE WHEN dx.seq_num = 10 THEN dx.icd_code END) AS dx_10_code,
    MAX(CASE WHEN dx.seq_num = 10 THEN dx.icd_version END) AS dx_10_version,
    MAX(CASE WHEN dx.seq_num = 10 THEN dx.long_title END) AS dx_10_title,
    -- For diagnosis 11 (seq_num = 11)
    MAX(CASE WHEN dx.seq_num = 11 THEN dx.icd_code END) AS dx_11_code,
    MAX(CASE WHEN dx.seq_num = 11 THEN dx.icd_version END) AS dx_11_version,
    MAX(CASE WHEN dx.seq_num = 11 THEN dx.long_title END) AS dx_11_title
FROM 
    sepsis_admissions AS s
LEFT JOIN 
    sepsis_diagnoses_icd AS dx
    ON s.hadm_id = dx.hadm_id
GROUP BY 
    s.hadm_id, s.subject_id;

/* Use case  sepsis admission with dx list in line */
CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DX AS
SELECT 
    s.*, 
    s1.*,
	(CASE WHEN s1.dx_1_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_2_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_3_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_4_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_5_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_6_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_7_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_8_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_9_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_10_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s1.dx_11_code IS NOT NULL THEN 1 ELSE 0 END) 
    AS diagnosis_count,

    CASE 
        WHEN spl.subject_id IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS sepsis_flag
FROM 
    sepsis_admissions AS s
LEFT JOIN 
    sepsis_diagnosis_in_line as s1
    ON s.hadm_id = s1.hadm_id_1
LEFT JOIN 
    (SELECT DISTINCT hadm_id, subject_id FROM sespsis_patient_list) AS spl
    ON s.hadm_id = spl.hadm_id;

  -- Add all non-aggregated columns from sepsis_admissions here
  
/* Use case 12 based on primary diagnosis, compute LOS and ED hours by  HADM ID and Subject ID */
CREATE VIEW patientprofileby_primary_x as
select dx_1_code, dx_1_title, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN hospital_expire_flag = 1 THEN hadm_id END) AS DEATH_COUNT  from SEPSIS_ADMISSION_WITHINLINE_DX
group by dx_1_code, dx_1_title;

CREATE VIEW patientprofileby_primary_x as
select dx_1_code, dx_1_title, count(distinct subject_id) as patientcount, count(distinct hadm_id) as visitcount,
COUNT(DISTINCT CASE WHEN hospital_expire_flag = 1 THEN hadm_id END) AS DEATH_COUNT  from SEPSIS_ADMISSION_WITHINLINE_DX
group by dx_1_code, dx_1_title;

/* compute the count of other diagnosis against each subject id and hadm ID*/
SELECT
    s.hadm_id,
    s.subject_id,
    -- Count non-null diagnosis codes
    (CASE WHEN s.dx_1_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_2_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_3_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_4_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_5_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_6_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_7_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_8_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_9_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_10_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN s.dx_11_code IS NOT NULL THEN 1 ELSE 0 END) 
    AS diagnosis_count
FROM
    SEPSIS_ADMISSION_WITHINLINE_DX AS s;
    
/* Adding dx ccount to the existing table */
ALTER TABLE SEPSIS_ADMISSION_WITHINLINE_DX
ADD COLUMN diagnosis_count INT;

UPDATE SEPSIS_ADMISSION_WITHINLINE_DX
SET diagnosis_count = 
    (CASE WHEN dx_1_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_2_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_3_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_4_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_5_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_6_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_7_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_8_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_9_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_10_code IS NOT NULL THEN 1 ELSE 0 END) + 
    (CASE WHEN dx_11_code IS NOT NULL THEN 1 ELSE 0 END); 
    
/* use case 19 : identify sepsis vs non sepsis code counts for each subject id and hadm ID */
CREATE VIEW SEPSISFLAG_COUNT AS
SELECT 
    subject_id,
    COUNT(DISTINCT CASE WHEN sepsis_flag = 'Yes' THEN hadm_id END) AS sepsis_flag_yes_count,
    COUNT(DISTINCT CASE WHEN sepsis_flag = 'No' THEN hadm_id END) AS sepsis_flag_no_count
FROM 
    SEPSIS_ADMISSION_WITHINLINE_DX
GROUP BY 
    subject_id;
    
/* USE CASE 22 : based on subject id and hadm id, populate the description of the drg  codes applicable to the hospital visit along with the drg severity and drg mortality  for APR DRGs  (if a valid APR DRG exists for each HADM ID) */
CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DX_DRG AS
select s1.*, s2.drg_type, s2.drg_code, s2.description, s2.drg_severity, s2.drg_mortality from SEPSIS_ADMISSION_WITHINLINE_DX as s1
LEFT JOIN drgcodes as s2
on s1.hadm_id = s2.hadm_id

select * from SEPSIS_ADMISSION_WITHINLINE_DX

CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DX_DRG AS
select s1.*, s2.drg_type, s2.drg_code, s2.description, s2.drg_severity, s2.drg_mortality from SEPSIS_ADMISSION_WITHINLINE_DX as s1
LEFT JOIN sepsis_drgcodes as s2
on s1.hadm_id = s2.hadm_id

select count(DISTINCT hadm_id) from sepsis_admissions

/* use case 23 based on the subject id and hadm id, provide list of medications , include unique list of medications */
CREATE VIEW SEPSIS_PRESCRIPTION_GROUPING_PRIMARY_DX AS
SELECT 
    s1.subject_id, 
    s1.hadm_id, 
    s1.sepsis_flag,
    s1.dx_1_code, 
    s1.dx_1_title,
    GROUP_CONCAT(DISTINCT s2.drug ORDER BY s2.drug) AS distinct_drugs
FROM 
    SEPSIS_ADMISSION_WITHINLINE_DX_DRG AS s1
LEFT JOIN 
    sepsis_prescripton AS s2
ON 
    s1.hadm_id = s2.hadm_id
GROUP BY 
    s1.subject_id, 
    s1.hadm_id,
    s1.sepsis_flag,
    s1.dx_1_code, s1.dx_1_title

select * from SEPSIS_ADMISSION_WITHINLINE_DX_DRG

select * from SEPSIS_PRESCRIPTION_WO_GROUPING_PRIMARY_DX

CREATE VIEW SEPSIS_PRESCRIPTION_WO_GROUPING_PRIMARY_DX AS
SELECT 
    s1.subject_id, 
    s1.hadm_id, 
    s1.sepsis_flag,
    s1.dx_1_code, 
    s1.dx_1_title,
    s2.drug 
FROM 
    SEPSIS_ADMISSION_WITHINLINE_DX_DRG AS s1
LEFT JOIN 
    sepsis_prescripton AS s2
ON 
    s1.hadm_id = s2.hadm_id
GROUP BY 
    s1.subject_id, 
    s1.hadm_id,
    s1.sepsis_flag,
    s1.dx_1_code, 
    s1.dx_1_title,
    s2.drug 
/* USE CASE 24 based on the subject id and hadm id  associate medications based on primary DRG code */

CREATE VIEW SEPSIS_PRESCRIPTION_GROUPING_DRG AS
SELECT 
    s1.subject_id, 
    s1.hadm_id, 
    s1.sepsis_flag,
    s1.drg_code, 
    s1.description,
    s1.drg_type,
    GROUP_CONCAT(DISTINCT s2.drug ORDER BY s2.drug) AS distinct_drugs
FROM 
    SEPSIS_ADMISSION_WITHINLINE_DX_DRG AS s1
LEFT JOIN 
    sepsis_prescripton AS s2
ON 
    s1.hadm_id = s2.hadm_id
GROUP BY 
    s1.subject_id, s1.hadm_id, s1.sepsis_flag, s1.drg_code, s1.description, s1.drg_type

/* USE 26 COMPLETED */
/*CREATE VIEW based on the subject id and hadm id  identify count of positive and negative events ( Administered / Flushed / Removed / Restarted  - positive task versus Negative task - Stopped, Delayed ) etc. */
CREATE VIEW U26_admissionwise_prescription_event_distribution_emar AS
SELECT 
    subject_id,
    hadm_id ,
    COUNT(CASE WHEN event_txt  ='Administered'  THEN 1 END) AS  Administered_cnt,
	COUNT(CASE WHEN event_txt  ='Administered Bolus from IV Drip'  THEN 1 END) AS  AdministeredBolusfromIVDrip_cnt,
	COUNT(CASE WHEN event_txt  ='Administered in Other Location'  THEN 1 END) AS  AdministeredinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Applied'  THEN 1 END) AS  Applied_cnt,
	COUNT(CASE WHEN event_txt  ='Applied in Other Location'  THEN 1 END) AS  AppliedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Assessed'  THEN 1 END) AS  Assessed_cnt,
	COUNT(CASE WHEN event_txt  ='Assessed in Other Location'  THEN 1 END) AS  AssessedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Confirmed'  THEN 1 END) AS  Confirmed_cnt,
	COUNT(CASE WHEN event_txt  ='Confirmed in Other Location'  THEN 1 END) AS  ConfirmedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed '  THEN 1 END) AS  Delayed_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Administered'  THEN 1 END) AS  DelayedAdministered_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Applied'  THEN 1 END) AS  DelayedApplied_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Assessed'  THEN 1 END) AS  DelayedAssessed_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Confirmed'  THEN 1 END) AS  DelayedConfirmed_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Flushed'  THEN 1 END) AS  DelayedFlushed_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Not Applied'  THEN 1 END) AS  DelayedNotApplied_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Not Confirmed'  THEN 1 END) AS  DelayedNotConfirmed_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Not Flushed'  THEN 1 END) AS  DelayedNotFlushed_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Removed'  THEN 1 END) AS  DelayedRemoved_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Restarted'  THEN 1 END) AS  DelayedRestarted_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Started'  THEN 1 END) AS  DelayedStarted_cnt,
	COUNT(CASE WHEN event_txt  ='Delayed Stopped'  THEN 1 END) AS  DelayedStopped_cnt,
	COUNT(CASE WHEN event_txt  ='Documented in O.R. Holding'  THEN 1 END) AS  DocumentedinORHolding_cnt,
	COUNT(CASE WHEN event_txt  ='Flushed'  THEN 1 END) AS  Flushed_cnt,
	COUNT(CASE WHEN event_txt  ='Flushed in Other Location'  THEN 1 END) AS  FlushedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Hold Dose'  THEN 1 END) AS  HoldDose_cnt,
	COUNT(CASE WHEN event_txt  ='Infusion Reconciliation'  THEN 1 END) AS  InfusionReconciliation_cnt,
	COUNT(CASE WHEN event_txt  ='Infusion Reconciliation Not Done'  THEN 1 END) AS  InfusionReconciliationNotDone_cnt,
	COUNT(CASE WHEN event_txt  ='Not Applied'  THEN 1 END) AS  NotApplied_cnt,
	COUNT(CASE WHEN event_txt  ='Not Assessed'  THEN 1 END) AS  NotAssessed_cnt,
	COUNT(CASE WHEN event_txt  ='Not Confirmed'  THEN 1 END) AS  NotConfirmed_cnt,
	COUNT(CASE WHEN event_txt  ='Not Flushed'  THEN 1 END) AS  NotFlushed_cnt,
	COUNT(CASE WHEN event_txt  ='Not Given'  THEN 1 END) AS  NotGiven_cnt,
	COUNT(CASE WHEN event_txt  ='Not Given per Sliding Scale'  THEN 1 END) AS  NotGivenperSlidingScale_cnt,
	COUNT(CASE WHEN event_txt  ='Not Given per Sliding Scale in Other Location'  THEN 1 END) AS  NotGivenperSlidingScaleinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Not Read'  THEN 1 END) AS  NotRead_cnt,
	COUNT(CASE WHEN event_txt  ='Not Removed'  THEN 1 END) AS  NotRemoved_cnt,
	COUNT(CASE WHEN event_txt  ='Not Started'  THEN 1 END) AS  NotStarted_cnt,
	COUNT(CASE WHEN event_txt  ='Not Started per Sliding Scale'  THEN 1 END) AS  NotStartedperSlidingScale_cnt,
	COUNT(CASE WHEN event_txt  ='Not Stopped'  THEN 1 END) AS  NotStopped_cnt,
	COUNT(CASE WHEN event_txt  ='Not Stopped per Sliding Scale'  THEN 1 END) AS  NotStoppedperSlidingScale_cnt,
	COUNT(CASE WHEN event_txt  ='Partial '  THEN 1 END) AS  Partial_cnt,
	COUNT(CASE WHEN event_txt  ='Partial Administered'  THEN 1 END) AS  PartialAdministered_cnt,
	COUNT(CASE WHEN event_txt  ='Rate Change'  THEN 1 END) AS  RateChange_cnt,
	COUNT(CASE WHEN event_txt  ='Rate Change in Other Location'  THEN 1 END) AS  RateChangeinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Read'  THEN 1 END) AS  Read_cnt,
	COUNT(CASE WHEN event_txt  ='Removed'  THEN 1 END) AS  Removed_cnt,
	COUNT(CASE WHEN event_txt  ='Removed - Unscheduled'  THEN 1 END) AS  RemovedUnscheduled_cnt,
	COUNT(CASE WHEN event_txt  ='Removed Existing / Applied New'  THEN 1 END) AS  RemovedExistingAppliedNew_cnt,
	COUNT(CASE WHEN event_txt  ='Removed Existing / Applied New in Other Location'  THEN 1 END) AS  RemovedExistingAppliedNewinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Removed in Other Location'  THEN 1 END) AS  RemovedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Restarted'  THEN 1 END) AS  Restarted_cnt,
	COUNT(CASE WHEN event_txt  ='Restarted in Other Location'  THEN 1 END) AS  RestartedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Started'  THEN 1 END) AS  Started_cnt,
	COUNT(CASE WHEN event_txt  ='Started in Other Location'  THEN 1 END) AS  StartedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Stopped'  THEN 1 END) AS  Stopped_cnt,
	COUNT(CASE WHEN event_txt  ='Stopped - Unscheduled'  THEN 1 END) AS  StoppedUnscheduled_cnt,
	COUNT(CASE WHEN event_txt  ='Stopped - Unscheduled in Other Location'  THEN 1 END) AS  StoppedUnscheduledinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='Stopped As Directed'  THEN 1 END) AS  StoppedAsDirected_cnt,
	COUNT(CASE WHEN event_txt  ='Stopped in Other Location'  THEN 1 END) AS  StoppedinOtherLocation_cnt,
	COUNT(CASE WHEN event_txt  ='TPN Rate Not Changed'  THEN 1 END) AS  TPNRateNotChanged_cnt
		-- Add more cases for other values
FROM sepsis_emar
GROUP BY subject_id, hadm_id;
    
SELECT 
    s1.product_description, 
    s1.administration_type, 
    COUNT(*), 
    s2.sepsis_flag, 
    s2.drg_code 
FROM 
    sepsis_emar_detail AS s1
LEFT JOIN 
    sepsis_admission_withinline_dx_drg AS s2
ON 
    s1.subject_id = s2.subject_id
GROUP BY 
    s1.product_description, 
    s1.administration_type, 
    s2.sepsis_flag, 
    s2.drg_code;
    
-- use case 37,38 Summarize patients by age, gender , DOD
CREATE VIEW PATIENT_BY_AGE_GENDER_ANCHOR_YEAR AS
select gender,year(dod) as yr,anchor_year,
CASE 
		WHEN anchor_age BETWEEN 0 AND 18 THEN '0-18'
		WHEN anchor_age BETWEEN 19 AND 35 THEN '19-35'
		WHEN anchor_age BETWEEN 36 AND 50 THEN '36-50'
		WHEN anchor_age BETWEEN 51 AND 65 THEN '51-65'
		WHEN anchor_age BETWEEN 66 AND 80 THEN '66-80'
		WHEN anchor_age > 80 THEN '81+'
		ELSE 'Unknown'
	END AS age_category,
    count(*) from sepsis_patients
group by gender,yr,age_category,anchor_year

/*use case 37 ended */
select priority, count(*) from sepsis_lab_events
group by priority 

ROUTINE	11204893
STAT	13373632
NULL	1969504
/* use case 37 completed */

/* Use case 33*/
select flag,count(*) from sepsis_lab_events
group by flag

NULL		16892962
abnormal	9655067
/* completed*/
/* use case 34 : Associate lab events with subject ID and HADM ID , DRG, Dx , Major organ group and chronic conditions, mortality status */
CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DXWITHLABEVENTS AS
select s1.*,s2.labeventscount from SEPSIS_ADMISSION_WITHINLINE_DX as s1
LEFT JOIN LABEVENTSCOUNT as s2
ON s1.hadm_id = s2.hadm_id

CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DXWITHLABEVENTS_DRG AS
select s1.*,s2.labeventscount from SEPSIS_ADMISSION_WITHINLINE_DX_DRG as s1
LEFT JOIN LABEVENTSCOUNT as s2
ON s1.hadm_id = s2.hadm_id
/* use case 34 completed */
/* use case 35 & 36 Summarize HCPCS code descriptions overall based on HADM ID , ICD code and DRG */
CREATE TABLE HCPCSEVENTS_BY_HADMID AS
SELECT 
    s.subject_id,
    s.hadm_id,
    GROUP_CONCAT(s.hcpcs_cd ORDER BY s.hcpcs_cd SEPARATOR ', ') AS hcpcs_codes,
    GROUP_CONCAT(s.short_description ORDER BY s.short_description SEPARATOR ', ') AS short_descriptions
FROM 
    sepis_hcpcsevents s
GROUP BY 
    s.subject_id, s.hadm_id;
    
CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DXWITHLABEVENTS_DRG_HCPCS_EVENTS AS
select s1.*,s2.hcpcs_codes,s2.short_descriptions from SEPSIS_ADMISSION_WITHINLINE_DX_DRG as s1
LEFT JOIN HCPCSEVENTS_BY_HADMID as s2
ON s1.hadm_id = s2.hadm_id;
/* use case 35 & 36 completed */
/* use case 39- 42 associate patient BMI  by mapping subject ID and comparing chart date of BMI with admission and discharge date ranges associated with a HADM ID associated with the subject ID */

CREATE TABLE SEPSIS_OMR_HMDID AS    
    SELECT 
    s1.subject_id,
    s1.chartdate,
    s2.hadm_id,
    s2.admittime,
    s2.dischtime,
    -- Add individual result_name columns using CASE
    MAX(CASE WHEN s1.result_name = 'Blood Pressure' THEN s1.result_value END) AS BloodPressure,
    MAX(CASE WHEN s1.result_name = 'Weight (Lbs)' THEN s1.result_value END) AS Weightlb,
    MAX(CASE WHEN s1.result_name = 'BMI (kg/m2)' THEN s1.result_value END) AS BMIkg,
    MAX(CASE WHEN s1.result_name = 'Blood Pressure Lying' THEN s1.result_value END) AS BPLying,
    MAX(CASE WHEN s1.result_name = 'Blood Pressure Sitting' THEN s1.result_value END) AS BPSitting,
    MAX(CASE WHEN s1.result_name = 'Blood Pressure Standing' THEN s1.result_value END) AS BPStanding,
    MAX(CASE WHEN s1.result_name = 'Blood Pressure Standing (1 min)' THEN s1.result_value END) AS BPStanding1min,
    MAX(CASE WHEN s1.result_name = 'eGFR' THEN s1.result_value END) AS eGFR,
    MAX(CASE WHEN s1.result_name = 'Blood Pressure Standing (3 min)' THEN s1.result_value END) AS BPStanding3min,
    MAX(CASE WHEN s1.result_name = 'Height' THEN s1.result_value END) AS Height,
    MAX(CASE WHEN s1.result_name = 'Height (Inches)' THEN s1.result_value END) AS HeightInches,
    MAX(CASE WHEN s1.result_name = 'Weight' THEN s1.result_value END) AS Weight,
    MAX(CASE WHEN s1.result_name = 'BMI' THEN s1.result_value END) AS BMI
FROM 
    sepsis_omr s1
JOIN 
    sepsis_admissions s2
    ON s1.subject_id = s2.subject_id
    AND s1.chartdate BETWEEN s2.admittime AND s2.dischtime
GROUP BY 
    s1.subject_id, s1.chartdate, s2.hadm_id, s2.admittime, s2.dischtime;


-- Alter the Sepsis OMR table subject id and hadm id

ALTER TABLE `prodrecom`.`sepsis_omr_hmdid` 
CHANGE COLUMN `dischtime` `dischtime1` DATETIME NULL DEFAULT NULL,
CHANGE COLUMN `admittime` `admittime1` DATETIME NULL DEFAULT NULL, 
CHANGE COLUMN `subject_id` `subject_id_2` INT NULL DEFAULT NULL ,
CHANGE COLUMN `hadm_id` `hadm_id_2` INT NULL DEFAULT NULL ;

CREATE VIEW SEPSIS_ADMISSION_WITHINLINE_DXWITH_LAB_DRG_HCPCS_OMR AS
select s1.*, s2.* from SEPSIS_ADMISSION_WITHINLINE_DXWITHLABEVENTS_DRG_HCPCS_EVENTS as s1
LEFT JOIN SEPSIS_OMR_HMDID as s2
on s1.hadm_id = s2.hadm_id_2;

/* use case 39 - 42 completed */
/* use case 43  44 */ 
select * from microbiologyevents;
select distinct test_name from microbiologyevents (158)
select distinct org_name from microbiologyevents  (452)
select distinct ab_name from microbiologyevents  (28)
/* use case 43  44  completed */
/* 45  47 */
select * from pharmacy
select * from procedureevents

-- table no1 sepsis_admissions

select * from sepsis_admission_withinline_dx_drg where subject_id = '10017886';
-- table no2 sepsis_prescripton
select * from sepsis_prescripton where subject_id = 10017886;
-- table no3 sepsis_hcpcsevents
select * from sepis_hcpcsevents where subject_id = 10017886;
-- table no4 
select * from sepsis_lab_events where subject_id = 10017886;
-- table no5
select * from sepsis_microbiologyevents where subject_id = 10017886;
-- table no6
select * from poe where subject_id = 10017886;
-- table no7

-- table no2 sepsis_prescripton
select s1.* from sepsis_prescripton as s1
left join sepsis_admission_withinline_dx_drg as s2
on s1.hadm_id = s2.hadm_id where s2.sepsis_flag = 'Yes'

select * from s_admissions_new;
select * from s_prescription;
select * from s_lab_events;
select * from s_microbiologyevents;
select * from s_poe;
select * from s_poe_detail;

-- table1
CREATE TABLE s_admissions_new as
select * from s_admissions where sepsis_flag = 'Yes' and drg_type='HCFA' and diabetic_flag="Yes";

-- table2
CREATE TABLE s_prescription
SELECT s1.*
FROM sepsis_prescripton AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.hadm_id = s2.hadm_id
      AND s2.sepsis_flag = 'Yes'
);

-- table 3
SELECT s1.*
FROM sepis_hcpcsevents AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.hadm_id = s2.hadm_id
      AND s2.sepsis_flag = 'Yes'
);
-- table 3
-- table 4
create table s_lab_events AS
SELECT s1.*
FROM lab_events AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.hadm_id = s2.hadm_id
      AND s2.sepsis_flag = 'Yes'
);
-- table 5
create table s_microbiologyevents AS
SELECT s1.*
FROM sepsis_microbiologyevents AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.hadm_id = s2.hadm_id
      AND s2.sepsis_flag = 'Yes'
);

-- table 6
create table s_poe AS
SELECT s1.*
FROM poe AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.hadm_id = s2.hadm_id
      AND s2.sepsis_flag = 'Yes'
);


create table s_poe_detail AS
SELECT s1.*
FROM poe_detail AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.subject_id = s2.subject_id
      AND s2.sepsis_flag = 'Yes'
);

create table s_poe_detail AS
SELECT s1.*, s2.hadm_id
FROM poe_detail AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_poe AS s2
    WHERE s1.poe_id = s2.poe_id
);

CREATE TABLE s_poe_detail AS
SELECT DISTINCT s1.*, s2.hadm_id, s2.ordertime
FROM poe_detail AS s1
INNER JOIN s_poe AS s2
ON s1.poe_id = s2.poe_id;


select * from sepsis_patients

SELECT s1.*
FROM emar_detail AS s1
WHERE EXISTS (
    SELECT 1
    FROM s_admissions_new AS s2
    WHERE s1.subject_id = s2.subject_id
      AND s2.sepsis_flag = 'Yes'
);



ALTER TABLE s_admissions
ADD COLUMN diabetic_flag VARCHAR(3) DEFAULT 'No';


UPDATE s_admissions
SET diabetic_flag = 
    CASE 
        WHEN 
            dx_1_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
) OR
            dx_2_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_3_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_4_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_5_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_6_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_7_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_8_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_9_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_10_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
)  OR
            dx_11_code IN ('24900', '24901', '24910', '24911', '24920', '24921', '24930', '24931', 
'24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25000', '25001', '25002', '25003', 
'25010', '25011', '25012', '25013', '25020', '25021', '25022', '25023', '25030', '25031', '25032', '25033', '25040', '25041', '25042', '25043', 
'25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', 
'25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36641', 'E0800', 'E0801', 'E0810', 'E0811', 
'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E083211', 'E083212', 'E083213', 'E083219', 'E08329', 'E083291', 'E083292', 
'E083293', 'E083299', 'E08331', 'E083311', 'E083312', 'E083313', 'E083319', 'E08339', 'E083391', 'E083392', 'E083393', 'E083399', 
'E08341', 'E083411', 'E083412', 'E083413', 'E083419', 'E08349', 'E083491', 'E083492', 'E083493', 'E083499', 'E08351', 'E083511', 
'E083512', 'E083513', 'E083519', 'E083521', 'E083522', 'E083523','E083529', 'E083531', 'E083532', 'E083533', 'E083539', 'E083541', 
'E083542', 'E083543', 'E083549', 'E083551', 'E083552', 'E083553','E083559', 'E08359', 'E083591', 'E083592', 'E083593', 'E083599', 
'E0836', 'E0837X1', 'E0837X2', 'E0837X3', 'E0837X9', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 
'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08641', 'E08649', 'E0865', 'E0869', 'E088', 'E089', 'E0900', 
'E0901', 'E0910', 'E0911', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E093211', 'E093212', 'E093213', 'E093219', 
'E09329', 'E093291', 'E093292', 'E093293', 'E093299', 'E09331', 'E093311', 'E093312', 'E093313', 'E093319', 'E09339', 'E093391', 
'E093392', 'E093393', 'E093399', 'E09341', 'E093411', 'E093412','E093413', 'E093419', 'E09349', 'E093491', 'E093492', 'E093493', 
'E093499', 'E09351', 'E093511', 'E093512', 'E093513', 'E093519','E093521', 'E093522', 'E093523', 'E093529', 'E093531', 'E093532', 
'E093533', 'E093539', 'E093541', 'E093542', 'E093543', 'E093549','E093551', 'E093552', 'E093553', 'E093559', 'E09359', 'E093591', 
'E093592', 'E093593', 'E093599', 'E0936', 'E0937X1', 'E0937X2', 'E0937X3', 'E0937X9', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 
'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09641', 
'E09649', 'E0965', 'E0969', 'E098', 'E099', 'E1010', 'E1011', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E103211', 'E103212', 
'E103213', 'E103219', 'E10329', 'E103291', 'E103292', 'E103293', 'E103299', 'E10331', 'E103311', 'E103312', 'E103313', 'E103319', 
'E10339', 'E103391', 'E103392', 'E103393', 'E103399', 'E10341', 'E103411', 'E103412', 'E103413', 'E103419', 'E10349', 'E103491', 
'E103492', 'E103493', 'E103499', 'E10351', 'E103511', 'E103512','E103513', 'E103519'
) 
        THEN 'Yes'
        ELSE 'No'
    END;
    


-- table no2 sepsis_prescripton
select * from sepsis_prescripton where subject_id = 10017886;
-- table no3 sepsis_hcpcsevents
select * from sepis_hcpcsevents where subject_id = 10017886;
-- table no4 
select * from sepsis_lab_events where subject_id = 10017886;
-- table no5
select * from sepsis_microbiologyevents where subject_id = 10017886;
-- table no6
select * from poe where subject_id = 10002013;
-- table no7

SELECT DISTINCT
    m.*,
    a.hadm_id
FROM 
    microbiologyevents AS m
JOIN 
    s_admissions_new AS a
ON 
    m.subject_id = a.subject_id
WHERE 
    m.chartdate BETWEEN a.admittime AND a.dischtime;


select count(*) from s_admissions_new 


    select count(distinct subject_id) from s_admissions where diabetic_flag="Yes"
    
    select count(distinct hadm_id) from s_admissions where diabetic_flag="Yes" and drg_type="HCFA"

CREATE TABLE s_admissions_new as
select s1.*, s2.gender, s2.anchor_age, s2.dod from s_admissions as s1
left join sepsis_patients as s2 on s1.subject_id = s2.subject_id
where s1.sepsis_flag = 'Yes' and s1.drg_type='HCFA' and s1.diabetic_flag="Yes"

select * from s_admissions_new
select * from patients

select * from ingredientevents

##omr
SELECT DISTINCT
    m.*,
    a.hadm_id
FROM 
    omr AS m
JOIN 
    s_admissions_new AS a
ON 
    m.subject_id = a.subject_id
WHERE 
    m.chartdate BETWEEN a.admittime AND a.dischtime;
    
    select * from poe_detail
    
select distinct order_type from poe

select distinct spec_type_desc from sepsis_microbiologyevents

