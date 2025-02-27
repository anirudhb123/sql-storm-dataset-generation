
WITH CustomerDemographics AS (
    SELECT DISTINCT cd_gender, 
           cd_marital_status, 
           cd_education_status,
           SUBSTRING(cd_education_status FROM 1 FOR 10) AS short_education,
           LENGTH(cd_education_status) AS education_length
    FROM customer_demographics
),
AddressDetails AS (
    SELECT ca_state, 
           ca_city,
           UPPER(ca_street_name) AS uppercase_street_name,
           CONCAT(ca_street_number, ' ', ca_street_type, ' ', ca_street_name) AS full_address
    FROM customer_address
),
DemographicsWithAddress AS (
    SELECT cd.gender, 
           cd.marital_status, 
           cd.short_education, 
           ad.ca_state, 
           ad.ca_city, 
           ad.uppercase_street_name, 
           ad.full_address 
    FROM CustomerDemographics cd
    JOIN AddressDetails ad ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL LIMIT 1 OFFSET FLOOR(RANDOM() * (SELECT COUNT(*) FROM customer)))
),
FinalResult AS (
    SELECT ad.ca_state,
           COUNT(*) AS count_gender,
           STRING_AGG(DISTINCT cd.short_education, ', ') AS unique_educations
    FROM DemographicsWithAddress cd 
    JOIN customer c ON cd.gender = c.c_first_name
    GROUP BY ad.ca_state
)
SELECT ca_state, 
       count_gender, 
       unique_educations
FROM FinalResult
WHERE count_gender > 10
ORDER BY ca_state;
