
WITH ProcessedAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS full_address,
        ca.ca_city,
        ca.ca_state,
        LENGTH(ca.ca_zip) AS zip_length
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city IS NOT NULL 
        AND ca.ca_state IS NOT NULL
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    pa.full_address,
    pa.ca_city,
    pa.ca_state,
    ps.customer_count,
    ps.total_dependents,
    ps.avg_purchase_estimate,
    pa.zip_length
FROM 
    ProcessedAddresses pa
JOIN 
    CustomerStats ps ON LENGTH(pa.full_address) % 10 = ps.customer_count % 10
WHERE 
    pa.zip_length BETWEEN 5 AND 10
ORDER BY 
    pa.ca_city, pa.ca_state, ps.customer_count DESC;
