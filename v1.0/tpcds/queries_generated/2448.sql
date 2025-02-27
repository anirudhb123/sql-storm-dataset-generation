
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.first_name,
        c.last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COALESCE(CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate > 5000 THEN 'High Value'
            ELSE 'Regular Value'
        END, 'No Purchases') AS value_category
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cs.first_name,
    cs.last_name,
    cs.marital_status,
    cs.value_category,
    COALESCE(rs.total_sales, 0) AS recent_total_sales,
    rs.order_count,
    RANK() OVER (ORDER BY COALESCE(rs.total_sales, 0) DESC) AS customer_rank
FROM 
    customer_stats cs
LEFT JOIN 
    ranked_sales rs ON cs.c_customer_sk = rs.bill_customer_sk
WHERE 
    cs.value_category != 'Unknown'
ORDER BY 
    recent_total_sales DESC
LIMIT 100;
