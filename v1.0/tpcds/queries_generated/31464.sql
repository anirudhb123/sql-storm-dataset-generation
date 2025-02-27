
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ci.hd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics ci ON c.c_current_hdemo_sk = ci.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ci.hd_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.hd_income_band_sk,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Spender'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS customer_segment
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_item_sk
WHERE 
    cs.total_orders > 0
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
