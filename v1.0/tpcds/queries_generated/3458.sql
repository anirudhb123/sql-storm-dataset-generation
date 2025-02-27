
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
avg_purchase AS (
    SELECT 
        ci.c_customer_sk,
        AVG(ci.cd_purchase_estimate) AS average_estimate
    FROM 
        customer_info ci
    GROUP BY 
        ci.c_customer_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ab.average_estimate
    FROM 
        customer_info ci
    JOIN 
        avg_purchase ab ON ci.c_customer_sk = ab.c_customer_sk
    WHERE 
        ab.average_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
),
returns_summary AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.return_qty) AS total_returns,
        COUNT(sr.return_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.returning_customer_sk
),
final_report AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.cd_gender,
        hvc.cd_marital_status,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (CASE WHEN rs.total_returns > 0 THEN 'Yes' ELSE 'No' END) AS returned_first_time,
        hvc.average_estimate
    FROM 
        high_value_customers hvc
    LEFT JOIN 
        returns_summary rs ON hvc.c_customer_sk = rs.returning_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_returns,
    fr.returned_first_time,
    fr.average_estimate
FROM 
    final_report fr
WHERE 
    fr.cd_gender IS NOT NULL
ORDER BY 
    fr.average_estimate DESC, 
    fr.c_last_name ASC;
