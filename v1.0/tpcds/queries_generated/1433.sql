
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) as sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        IFNULL(SUM(CASE WHEN st.st_store_name IS NOT NULL THEN 1 ELSE 0 END), 0) AS store_purchases
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store st ON ss.ss_store_sk = st.s_store_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
profitable_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        SUM(ss.ss_net_profit) AS total_profit
    FROM item item
    LEFT JOIN store_sales ss ON item.i_item_sk = ss.ss_item_sk
    GROUP BY item.i_item_id, item.i_item_desc, item.i_current_price
)

SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.store_purchases,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    pi.i_item_id,
    pi.i_item_desc,
    pi.i_current_price,
    pi.total_profit
FROM customer_info ci
JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
JOIN profitable_items pi ON ss.ws_item_sk = pi.i_item_id
WHERE ci.cd_purchase_estimate > 5000 
  AND ss.total_sales > 1000 
  AND pi.total_profit IS NOT NULL
ORDER BY pi.total_profit DESC, ci.store_purchases DESC
LIMIT 100;

