
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city, 
        ca_state
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressGender AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        c.full_name,
        c.cd_gender
    FROM AddressParts a
    JOIN CustomerDetails c ON c.c_customer_sk = (SELECT TOP 1 c_customer_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk)
),
GenderCount AS (
    SELECT 
        ca_state, 
        cd_gender, 
        COUNT(*) AS gender_count
    FROM AddressGender
    GROUP BY ca_state, cd_gender
),
FinalReport AS (
    SELECT 
        ca_state,
        SUM(CASE WHEN cd_gender = 'M' THEN gender_count ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN gender_count ELSE 0 END) AS female_count
    FROM GenderCount
    GROUP BY ca_state
)
SELECT 
    ca_state,
    male_count,
    female_count,
    (male_count + female_count) AS total_count,
    ROUND((male_count::decimal / NULLIF((male_count + female_count), 0)) * 100, 2) AS male_percentage,
    ROUND((female_count::decimal / NULLIF((male_count + female_count), 0)) * 100, 2) AS female_percentage
FROM FinalReport
ORDER BY ca_state;
