
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.purchase_estimate_band
    FROM RankedCustomers rc
    WHERE rc.rn <= 10
)
SELECT 
    tc.cd_gender,
    COUNT(*) AS customer_count,
    AVG(LENGTH(tc.full_name)) AS avg_name_length,
    STRING_AGG(tc.full_name, ', ') AS top_customers
FROM TopCustomers tc
GROUP BY tc.cd_gender
ORDER BY tc.cd_gender;
