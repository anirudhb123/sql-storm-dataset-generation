
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, COALESCE(CONCAT(' Apt ', ca_suite_number), '')) AS full_address
    FROM 
        customer_address
),
customer_information AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
return_statistics AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.return_amt) AS total_return_amount,
        COUNT(*) AS total_return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
),
final_benchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_return_count, 0) AS total_return_count,
        ci.full_address
    FROM 
        customer_information ci
    LEFT JOIN 
        return_statistics rs ON ci.c_customer_sk = rs.returning_customer_sk
)
SELECT 
    fb.full_name,
    fb.cd_gender,
    fb.cd_marital_status,
    fb.cd_purchase_estimate,
    fb.total_return_amount,
    fb.total_return_count,
    fb.full_address
FROM 
    final_benchmark fb
WHERE 
    fb.cd_purchase_estimate > 500 
ORDER BY 
    fb.total_return_count DESC, fb.total_return_amount DESC
LIMIT 100;
