
WITH Address_Info AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Customer_Info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ai.full_address,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Info ai ON c.c_current_addr_sk = ai.ca_address_sk
),
Aggregate_Info AS (
    SELECT 
        ci.cd_gender,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT CONCAT(ci.c_first_name, ' ', ci.c_last_name) ORDER BY ci.c_first_name) AS customer_names
    FROM 
        Customer_Info ci
    GROUP BY 
        ci.cd_gender
)
SELECT 
    ai.cd_gender,
    ai.customer_count,
    ai.avg_purchase_estimate,
    (SELECT STRING_AGG(full_address SEPARATOR '; ') FROM Address_Info ai WHERE ai.ca_city = 'San Francisco') AS san_francisco_addresses,
    ai.customer_names
FROM 
    Aggregate_Info ai
ORDER BY 
    ai.cd_gender;
