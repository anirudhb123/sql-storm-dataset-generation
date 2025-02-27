
WITH Address_Components AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer_demographics
),
Address_Summary AS (
    SELECT 
        ac.ca_address_sk,
        COUNT(d.cd_demo_sk) AS customer_count,
        MAX(d.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(d.cd_purchase_estimate) AS min_purchase_estimate,
        AVG(d.cd_purchase_estimate) AS avg_purchase_estimate
    FROM Address_Components ac
    JOIN customer c ON c.c_current_addr_sk = ac.ca_address_sk
    JOIN Demographics d ON d.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY ac.ca_address_sk
)
SELECT 
    asc.full_address,
    asc.customer_count,
    asc.max_purchase_estimate,
    asc.min_purchase_estimate,
    asc.avg_purchase_estimate,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ac.ca_country
FROM Address_Summary asc
JOIN Address_Components ac ON ac.ca_address_sk = asc.ca_address_sk
ORDER BY asc.avg_purchase_estimate DESC
LIMIT 10;
