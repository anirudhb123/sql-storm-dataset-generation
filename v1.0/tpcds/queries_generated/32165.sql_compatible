
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    WHERE ws_ship_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
total_sales AS (
    SELECT 
        si.ws_item_sk,
        SUM(si.ws_ext_sales_price) AS total_revenue,
        COUNT(si.ws_order_number) AS order_count
    FROM sales_cte si
    WHERE si.rn = 1
    GROUP BY si.ws_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        t.total_revenue,
        t.order_count,
        ROW_NUMBER() OVER (ORDER BY t.total_revenue DESC) AS item_rank
    FROM item i
    JOIN total_sales t ON i.i_item_sk = t.ws_item_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ii.i_item_desc,
    ii.i_current_price,
    ii.total_revenue,
    ii.order_count,
    ci.cd_gender,
    ci.cd_marital_status
FROM customer_info ci
LEFT JOIN item_info ii ON ci.c_customer_sk = (SELECT c_current_hdemo_sk FROM customer WHERE c_customer_sk = ci.c_customer_sk)
WHERE (ci.cd_marital_status = 'M' OR ci.cd_gender = 'F') 
AND ii.item_rank <= 10 
AND ii.total_revenue IS NOT NULL
ORDER BY ii.total_revenue DESC;
