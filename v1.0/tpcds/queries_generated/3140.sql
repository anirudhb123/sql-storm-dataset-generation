
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.bill_customer_sk
),
customer_with_demo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        r.bill_customer_sk,
        r.total_sales,
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        r.sales_rank
    FROM 
        ranked_sales r
    JOIN 
        customer_with_demo cd ON r.bill_customer_sk = cd.c_customer_id
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    SUM(ws.ws_quantity) AS total_items_sold,
    MAX(ws.ws_net_paid) AS highest_order_value,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    STRING_AGG(DISTINCT cd.ib_income_band_sk::text, ',') AS income_band_list
FROM 
    top_customers tc
JOIN 
    web_sales ws ON tc.bill_customer_sk = ws.ws_bill_customer_sk
JOIN 
    income_band cd ON tc.cd_income_band_sk = cd.ib_income_band_sk
GROUP BY 
    tc.c_customer_id
HAVING 
    SUM(ws.ws_quantity) > 50 AND 
    MAX(ws.ws_net_paid) IS NOT NULL
ORDER BY 
    total_items_sold DESC;
