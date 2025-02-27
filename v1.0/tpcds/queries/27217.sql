
WITH CustomerAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number)
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
), DemographicData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer_demographics
), CustomerFullDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN CustomerAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN DemographicData cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), BenchmarkData AS (
    SELECT 
        customer_name,
        full_address,
        ca_city,
        ca_state,
        ca_zip,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_segment
    FROM CustomerFullDetails
)
SELECT 
    purchase_segment,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT cd_gender, ', ') AS genders,
    STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
FROM BenchmarkData
GROUP BY 
    purchase_segment
ORDER BY 
    purchase_segment;
