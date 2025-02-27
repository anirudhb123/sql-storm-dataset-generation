
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id
),
CTE_Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        RANK() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
CTE_Sales_Analysis AS (
    SELECT
        cc.c_customer_id,
        ccs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.gender_rank,
        CASE 
            WHEN ccs.total_sales > 1000 THEN 'High Value'
            WHEN ccs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM CTE_Customer_Sales ccs
    JOIN CTE_Customer_Demographics cd ON ccs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    sa.customer_value,
    COUNT(sa.c_customer_id) AS customer_count,
    AVG(sa.total_sales) AS avg_sales,
    MAX(sa.total_sales) AS max_sales
FROM CTE_Sales_Analysis sa
WHERE sa.gender_rank = 1 OR sa.cd_marital_status = 'M'
GROUP BY sa.customer_value
ORDER BY customer_count DESC
LIMIT 10
UNION ALL
SELECT 
    'Total Count' AS customer_value,
    COUNT(*) AS customer_count,
    NULL AS avg_sales,
    NULL AS max_sales
FROM CTE_Sales_Analysis;
