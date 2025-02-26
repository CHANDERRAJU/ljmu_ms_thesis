CREATE TABLE SESPSIS_PATIENT_LIST AS
SELECT 
    a.hadm_id,
    a.subject_id,
    a.admittime, -- include all required fields from admissions table
    a.dischtime, -- include all required fields from admissions table
    a.deathtime,
    a.admission_type,
    a.admit_provider_id,
    a.admission_location,
    a.discharge_location,
    a.insurance,
    a.language,
    a.marital_status,
    a.race,
    a.edregtime,
    a.edouttime,
    a.hospital_expire_flag,
    d.drg_code,
    d.drg_type,
    d.description,
    GROUP_CONCAT(DISTINCT di.icd_code ORDER BY di.icd_code SEPARATOR ',') AS diagnosis_codes
FROM 
    admissions a
JOIN 
    drgcodes d ON a.hadm_id = d.hadm_id
JOIN 
    (SELECT hadm_id, GROUP_CONCAT(DISTINCT icd_code ORDER BY icd_code SEPARATOR ',') AS icd_code
     FROM diagnoses_icd
     GROUP BY hadm_id) di ON a.hadm_id = di.hadm_id
WHERE 
    d.drg_code IN ('870', '871', '872', '720', '721', '722', '723', '724', '725', '853', '854', '855', '856', '857', '858', '859', '860', '861', '862', '863', '947') -- specify your conditions here
GROUP BY 
    a.hadm_id,
    a.subject_id,
    a.admittime, -- include all required fields from admissions table
    a.dischtime, -- include all required fields from admissions table
    a.deathtime,
    a.admission_type,
    a.admit_provider_id,
    a.admission_location,
    a.discharge_location,
    a.insurance,
    a.language,
    a.marital_status,
    a.race,
    a.edregtime,
    a.edouttime,
    a.hospital_expire_flag,
    d.drg_code,
    d.drg_type,
    d.description
UNION
SELECT 
    a.hadm_id,
    a.subject_id,
    a.admittime, -- include all required fields from admissions table
    a.dischtime, -- include all required fields from admissions table
    a.deathtime,
    a.admission_type,
    a.admit_provider_id,
    a.admission_location,
    a.discharge_location,
    a.insurance,
    a.language,
    a.marital_status,
    a.race,
    a.edregtime,
    a.edouttime,
    a.hospital_expire_flag,
    d.drg_code,
    d.drg_type,
    d.description,
    GROUP_CONCAT(DISTINCT di.icd_code ORDER BY di.icd_code SEPARATOR ',') AS diagnosis_codes
FROM 
    admissions a
JOIN 
    drgcodes d ON a.hadm_id = d.hadm_id
JOIN 
    (SELECT hadm_id, icd_code
     FROM diagnoses_icd
     WHERE icd_code IN ('A021','A021','A207','A227','A267','A327','A391','A392','A393','A394','A3989',
'A399','A400','A401','A403','A408','A409','A4101','A4102','A411','A412','A413','A414','A4150','A4151',
'A4152','A4153','A4159','A4181','A4189','A419','A427','A5486','B007','B377','R571','R578',
'R6520','R6521','R7881','0031','0202','0223','0380','03810','03811','03812','03819',
'0382','0383','03840','03841','03842','03843','03844','03849',
'0388','0389','0545','41512','42292','449','67020','67022',
'67024','67030','67032','67034','67330','67331','67332','67333',
'67334','73340','73341','73342','73343','73344','73345','73349',
'77181','78552','99591','99592','99802','O85','085') -- specify your conditions here
    ) di ON a.hadm_id = di.hadm_id
GROUP BY 
    a.hadm_id,
    a.subject_id,
    a.admittime, -- include all required fields from admissions table
    a.dischtime, -- include all required fields from admissions table
    a.deathtime,
    a.admission_type,
    a.admit_provider_id,
    a.admission_location,
    a.discharge_location,
    a.insurance,
    a.language,
    a.marital_status,
    a.race,
    a.edregtime,
    a.edouttime,
    a.hospital_expire_flag,
    d.drg_code,
    d.drg_type,
    d.description