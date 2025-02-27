
WITH demographic_data AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(cs.cs_sales_price, 0)) AS total_sales
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        store_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), return_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROUND(SUM(COALESCE(cr.cr_return_quantity, 0)) * 1.0 / NULLIF(COUNT(DISTINCT c.c_customer_id), 0), 2) AS return_rate,
        ROUND(SUM(COALESCE(cs.cs_sales_price, 0)) * 1.0 / NULLIF(COUNT(DISTINCT c.c_customer_id), 0), 2) AS average_sales_per_customer
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        store_returns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    na.cd_gender,
    na.cd_marital_status,
    na.cd_education_status,
    na.return_rate,
    na.average_sales_per_customer,
    CASE 
        WHEN na.return_rate > 0.1 THEN 'High Return'
        WHEN na.return_rate BETWEEN 0.05 AND 0.1 THEN 'Moderate Return'
        ELSE 'Low Return' 
    END AS return_category
FROM 
    return_analysis na
ORDER BY 
    na.cd_gender, na.cd_marital_status, na.cd_education_status;
