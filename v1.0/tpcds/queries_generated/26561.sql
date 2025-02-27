
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rnk
    FROM customer_address
),
MaxRankedAddresses AS (
    SELECT 
        ca_state,
        MAX(rnk) AS max_rnk
    FROM RankedAddresses
    GROUP BY ca_state
),
FilteredAddresses AS (
    SELECT 
        ra.*
    FROM RankedAddresses ra
    INNER JOIN MaxRankedAddresses mra 
        ON ra.rnk = mra.max_rnk AND ra.ca_state = mra.ca_state
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    f.full_address,
    cd.cd_gender,
    cd.cd_marital_status
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN FilteredAddresses f ON c.c_current_addr_sk = f.ca_address_sk
WHERE cd.cd_gender = 'F'
ORDER BY c.c_last_name, c.c_first_name;
