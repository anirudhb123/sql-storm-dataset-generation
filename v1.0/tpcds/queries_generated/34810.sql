
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.cd_income_band_sk,
        cs.order_count,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_summary cs
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    tc.total_spent,
    sd.total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.cd_gender = 'M' THEN 'Male'
        WHEN tc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender
FROM 
    customer_address ca
FULL OUTER JOIN 
    top_customers tc ON ca.ca_address_sk = tc.c_customer_sk
LEFT JOIN 
    sales_data sd ON tc.c_customer_sk = sd.ws_item_sk
WHERE 
    (tc.total_spent IS NOT NULL OR sd.total_sales IS NOT NULL)
    AND tc.rank <= 10
ORDER BY 
    total_spent DESC, total_sales DESC;
