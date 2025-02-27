
WITH normalized_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS normalized_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
frequent_addresses AS (
    SELECT 
        normalized_address,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip), '; ') AS address_details
    FROM 
        normalized_addresses
    GROUP BY 
        normalized_address
    HAVING 
        COUNT(*) > 1
),
customer_info AS (
    SELECT 
        cust.c_customer_sk,
        CONCAT(cust.c_first_name, ' ', cust.c_last_name) AS full_name,
        demo.cd_gender,
        demo.cd_marital_status,
        demo.cd_education_status,
        addr.normalized_address,
        addr.address_count,
        addr.address_details
    FROM 
        customer AS cust
    JOIN 
        customer_demographics AS demo ON cust.c_current_cdemo_sk = demo.cd_demo_sk
    JOIN 
        normalized_addresses AS addr ON cust.c_current_addr_sk = addr.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    normalized_address,
    address_count,
    address_details
FROM 
    customer_info
ORDER BY 
    address_count DESC, 
    full_name;
