
WITH AddressParts AS (
    SELECT 
        ca_address_sk, 
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ca_city, 
        ca_state, 
        ca_zip
    FROM customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM customer_demographics
),
JoinedData AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS customer_name, 
        a.full_address, 
        a.ca_city, 
        a.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        CASE 
            WHEN d.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN d.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN d.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_segment
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    COUNT(*) AS total_customers,
    purchase_segment,
    COUNT(*) FILTER (WHERE cd_gender = 'M') AS male_count,
    COUNT(*) FILTER (WHERE cd_gender = 'F') AS female_count,
    STRING_AGG(DISTINCT full_address, '; ') AS unique_addresses
FROM JoinedData
GROUP BY purchase_segment
ORDER BY purchase_segment;
