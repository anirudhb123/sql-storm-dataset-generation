
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        sr.ws_item_sk,
        sr.total_sales,
        ROW_NUMBER() OVER (ORDER BY sr.total_sales DESC) AS rank
    FROM sales_rank sr
    WHERE sr.sales_rank = 1
    LIMIT 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(sd.total_net_paid, 0) AS total_net_paid,
    COALESCE(sd.order_count, 0) AS order_count,
    ti.total_sales AS item_sales,
    CASE 
        WHEN ci.cd_gender = 'M' THEN 'Male'
        WHEN ci.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender_description
FROM customer_info ci
LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN top_items ti ON ti.ws_item_sk = (
    SELECT ws_item_sk 
    FROM web_sales 
    ORDER BY ws_net_paid DESC 
    LIMIT 1
    OFFSET (SELECT COUNT(1) FROM top_items) - 1
)
ORDER BY item_sales DESC, total_net_paid DESC;
