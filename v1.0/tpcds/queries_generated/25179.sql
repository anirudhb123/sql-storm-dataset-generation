
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        INITCAP(ca_street_name) AS formatted_street_name,
        TRIM(REPLACE(ca_city, ' ', '_')) AS formatted_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        CONCAT(formatted_street_name, ', ', formatted_city) AS address_summary
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
)
SELECT 
    cd.full_name,
    cd.gender,
    cd.marital_status,
    pa.full_address,
    COUNT(r.r_reason_sk) AS return_count
FROM 
    customer_details cd
LEFT JOIN 
    store_returns r ON cd.c_customer_sk = r.sr_customer_sk
GROUP BY 
    cd.full_name, cd.gender, cd.marital_status, pa.full_address
ORDER BY 
    return_count DESC, cd.full_name ASC
LIMIT 100;
