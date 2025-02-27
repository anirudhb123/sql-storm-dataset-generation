
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 0 AS level
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price * 0.9, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 3
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        (SELECT COUNT(*) FROM store_sales WHERE ss_customer_sk = c.c_customer_sk) AS total_sales,
        (SELECT SUM(ss_net_profit) FROM store_sales WHERE ss_customer_sk = c.c_customer_sk) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    ih.i_item_id,
    ih.i_item_desc,
    ih.i_current_price,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_profit, 0) AS total_profit
FROM customer_summary ch
LEFT JOIN item_hierarchy ih ON ih.level = 2
LEFT JOIN sales_data sd ON sd.ws_item_sk = ih.i_item_sk 
WHERE ch.total_sales > 10 
  AND (ih.i_current_price IS NOT NULL OR ih.i_current_price <> 0)
  AND NOT EXISTS (
      SELECT 1 
      FROM store_returns sr 
      WHERE sr.sr_customer_sk = ch.c_customer_sk
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt_inc_tax IS NOT NULL
  )
ORDER BY ch.c_last_name, ch.c_first_name, total_profit DESC
FETCH FIRST 50 ROWS ONLY;
