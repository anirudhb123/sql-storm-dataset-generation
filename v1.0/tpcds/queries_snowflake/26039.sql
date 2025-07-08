
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
Customer_Demo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
),
Aggregated_Info AS (
    SELECT 
        ai.ca_address_sk,
        ci.cd_demo_sk,
        COUNT(*) AS address_count,
        MAX(ai.street_name_length) AS max_street_name_length,
        MIN(ai.street_name_length) AS min_street_name_length,
        LISTAGG(ai.full_address, ', ') WITHIN GROUP (ORDER BY ai.full_address) AS all_addresses
    FROM 
        Address_Info ai
    JOIN 
        web_sales ws ON ws.ws_bill_addr_sk = ai.ca_address_sk
    JOIN 
        Customer_Demo ci ON ws.ws_bill_cdemo_sk = ci.cd_demo_sk
    GROUP BY 
        ai.ca_address_sk, ci.cd_demo_sk
)
SELECT 
    a.ca_address_sk,
    c.cd_demo_sk,
    c.gender_marital_status,
    a.address_count,
    a.max_street_name_length,
    a.min_street_name_length,
    a.all_addresses
FROM 
    Aggregated_Info a
JOIN 
    Customer_Demo c ON a.cd_demo_sk = c.cd_demo_sk
WHERE 
    c.cd_education_status LIKE '%Graduate%'
ORDER BY 
    a.address_count DESC, a.max_street_name_length ASC;
