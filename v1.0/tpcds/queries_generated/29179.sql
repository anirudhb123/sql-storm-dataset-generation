
WITH concatenated_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Apt ', ca_suite_number), ''), ', ', 
               ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
demographic_analysis AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT full_address, '; ') AS addresses
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        concatenated_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd_gender
),
max_demographics AS (
    SELECT 
        cd_gender, 
        MAX(avg_purchase_estimate) AS max_avg_purchase
    FROM 
        demographic_analysis
    GROUP BY 
        cd_gender
)
SELECT 
    da.cd_gender,
    da.customer_count,
    da.avg_purchase_estimate,
    da.addresses
FROM 
    demographic_analysis da
JOIN 
    max_demographics md ON da.cd_gender = md.cd_gender 
                        AND da.avg_purchase_estimate = md.max_avg_purchase;
