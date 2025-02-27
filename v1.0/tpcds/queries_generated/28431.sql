
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || 
        TRIM(ca_street_name) || ' ' || 
        TRIM(ca_street_type) || 
        CASE 
            WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || TRIM(ca_suite_number) 
            ELSE '' 
        END AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address,
        a.ca_city,
        a.ca_state
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
),
AggregateInfo AS (
    SELECT 
        COUNT(*) AS customer_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM CustomerInfo
)
SELECT 
    customer_count,
    male_count,
    female_count,
    avg_purchase_estimate,
    CONCAT('Total customers: ', customer_count, 
           ', Males: ', male_count, 
           ', Females: ', female_count, 
           ', Avg Purchase Estimate: $', ROUND(avg_purchase_estimate, 2)) AS summary_info
FROM AggregateInfo;
