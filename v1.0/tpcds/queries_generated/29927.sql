
WITH AddressDetail AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer_demographics cd
), CombinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN AddressDetail ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    gender,
    COUNT(*) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(c_first_name, ' ', c_last_name, ' - ', full_address), '; ') AS customer_list
FROM CombinedData cd
LEFT JOIN customer_demographics cdem ON cd.c_customer_sk = cdem.cd_demo_sk
GROUP BY gender
ORDER BY customer_count DESC;
