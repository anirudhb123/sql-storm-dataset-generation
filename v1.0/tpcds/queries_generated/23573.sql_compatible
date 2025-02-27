
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        AND ws.ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022
        )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), ranked_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
), elite_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        r.order_count
    FROM ranked_sales r
    WHERE r.sales_rank <= 100
), demographic_analysis AS (
    SELECT 
        ec.c_customer_sk,
        ec.c_first_name,
        ec.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        CASE 
            WHEN d.cd_purchase_estimate IS NULL THEN 'Unknown Purchaser'
            WHEN d.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS purchase_category
    FROM elite_customers ec
    LEFT JOIN customer_demographics d ON ec.c_customer_sk = d.cd_demo_sk
)
SELECT 
    da.c_customer_sk,
    da.c_first_name,
    da.c_last_name,
    COALESCE(da.cd_gender, 'N/A') AS gender,
    COALESCE(da.cd_marital_status, 'N/A') AS marital_status,
    da.purchase_category,
    CASE 
        WHEN da.purchase_category = 'High Value' AND da.cd_marital_status = 'M' THEN 'Promote'
        WHEN da.purchase_category = 'Low Value' AND da.cd_gender = 'F' THEN 'Engage'
        ELSE 'Monitor'
    END AS action_plan
FROM demographic_analysis da
WHERE da.purchase_category IS NOT NULL
ORDER BY da.total_sales DESC, da.c_last_name ASC;
