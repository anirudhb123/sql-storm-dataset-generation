
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        DATE(d.d_date) AS sales_date,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY DATE(d.d_date) DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.web_site_sk, d.d_date
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating
    FROM customer_info ci
    WHERE ci.rn <= 10
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS warehouse_total_sales
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT 
    sd.sales_date,
    sd.total_sales,
    tc.cd_gender,
    tc.cd_marital_status,
    SUM(ws.ws_net_paid) OVER (PARTITION BY tc.cd_gender) AS gender_based_sales,
    ws.warehouse_total_sales,
    (CASE 
        WHEN tc.cd_purchase_estimate IS NULL THEN 'UNKNOWN' 
        ELSE tc.cd_credit_rating 
    END) AS credit_rating_status
FROM sales_data sd
JOIN top_customers tc ON sd.web_site_sk = tc.c_customer_sk
LEFT JOIN warehouse_sales ws ON sd.web_site_sk = ws.w_warehouse_sk
WHERE sd.total_sales > 5000
ORDER BY sd.sales_date DESC, gender_based_sales DESC;
