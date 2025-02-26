/* sepsis_admissions completed*/
CREATE TABLE sepsis_admissions as 
SELECT *
FROM admissions
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST);

/* sepsis_datetimeevents completed*/
CREATE TABLE sepsis_datetimeevents as 
SELECT *
FROM datetimeevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST);

/* sepsis_diagnoses_icd completed*/
CREATE TABLE sepsis_diagnoses_icd as
SELECT 
    sdi.*,
    dx.long_title
FROM 
    diagnoses_icd sdi
JOIN 
    d_icd_diagnoses as dx 
    ON sdi.icd_code = dx.icd_code
    AND sdi.icd_version = dx.icd_version
WHERE sdi.subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST);
 
select * from sepsis_diagnoses_icd

/* sepsis_drgcodes completed*/
CREATE TABLE sepsis_drgcodes as 
SELECT *
FROM drgcodes
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST);

/* sepsis_emar completed*/
CREATE TABLE sepsis_emar as 
SELECT *
FROM emar
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) and charttime <= '2150-12-31'

/* sepsis_emar_detail completed*/
CREATE TABLE sepsis_emar_detail as 
SELECT *
FROM emar_detail
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) 

/* sepsis_hcpcsevents completed*/
CREATE TABLE sepis_hcpcsevents as 
SELECT *
FROM hcpcsevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) 

/* sepsis_hcpcsevents completed*/
CREATE TABLE sepsis_icustays as 
SELECT *
FROM icustays
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) 

/* sepsis_ingredientevents */
CREATE TABLE sepsis_ingredientevents as 
SELECT *
FROM ingredientevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) 

/* sepsis_labevents */
CREATE TABLE sepsis_inputevents as 
SELECT *
FROM inputevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) 

/* sepsis_microbiologyevents */
CREATE TABLE sepsis_microbiologyevents as 
SELECT *
FROM microbiologyevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST) 

/* sepsis_omar */
CREATE TABLE sepsis_omr as 
SELECT *
FROM omr
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

/* sepsis_outputevents */
CREATE TABLE sepsis_outputevents as 
SELECT *
FROM outputevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

/* sepsis_patients */
CREATE TABLE sepsis_patients as 
SELECT *
FROM patients
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

/* sepsis_pharmacy */
CREATE TABLE sepsis_pharmacy as 
SELECT *
FROM pharmacy
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)


/* poe */
CREATE TABLE sepsis_poe as 
SELECT *
FROM poe
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

/* sepsis poe_detail*/
CREATE TABLE sepsis_poe_detail as 
SELECT *
FROM poe_detail
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

/* sepsis prescription */
CREATE TABLE sepsis_prescripton as 
SELECT *
FROM prescription
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

/* sepsis procedureevents */
CREATE TABLE sepsis_procedureevents as 
SELECT *
FROM procedureevents
WHERE subject_id IN (SELECT DISTINCT subject_id FROM SESPSIS_PATIENT_LIST)

select count(*) from sepsis_admissions