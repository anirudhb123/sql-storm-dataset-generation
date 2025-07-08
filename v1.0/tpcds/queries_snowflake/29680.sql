
WITH Address_Concatenation AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
Customer_Aggregation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LISTAGG(DISTINCT CONCAT(ca.full_address, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip), '; ') WITHIN GROUP (ORDER BY ca.full_address) AS complete_addresses
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN Address_Concatenation ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    SPLIT_PART(c.complete_addresses, ';', 1) AS primary_address,
    SPLIT_PART(c.complete_addresses, ';', 2) AS secondary_address,
    LENGTH(c.complete_addresses) AS total_address_length
FROM Customer_Aggregation c
WHERE LENGTH(c.complete_addresses) > 100
ORDER BY total_address_length DESC
LIMIT 50;
