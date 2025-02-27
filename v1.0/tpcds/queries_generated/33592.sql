
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_income_band,
        ci.total_orders,
        ci.avg_order_value,
        NTILE(10) OVER (ORDER BY ci.total_orders DESC) AS income_band_rank
    FROM 
        customer_info ci
    WHERE 
        ci.total_orders > 0
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_income_band,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(tc.avg_order_value) AS avg_order_value,
    CASE 
        WHEN tc.total_orders IS NULL THEN 'No orders'
        ELSE 'Orders present'
    END AS order_status
FROM 
    top_customers tc
LEFT JOIN 
    store_sales ss ON tc.c_customer_sk = ss.ss_customer_sk
WHERE 
    tc.income_band_rank = 1
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.cd_income_band
HAVING 
    total_sales > 5000
ORDER BY 
    total_sales DESC;
