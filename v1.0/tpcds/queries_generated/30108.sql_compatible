
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           SUM(ws_quantity) AS total_sales,
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT sd.ws_item_sk,
           i.i_product_name,
           i.i_brand,
           sd.total_sales,
           sd.total_profit
    FROM sales_data sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE sd.rank <= 10
),
customer_data AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT cd.c_customer_sk,
           cd.c_first_name,
           cd.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate
    FROM customer_data cd
    WHERE cd.gender_rank <= 5
)
SELECT ti.i_product_name,
       ti.i_brand,
       tc.c_first_name,
       tc.c_last_name,
       tc.cd_gender,
       SUM(ti.total_sales) AS total_sales,
       SUM(ti.total_profit) AS total_profit,
       COUNT(tc.c_customer_sk) AS customer_count
FROM top_items ti
LEFT JOIN top_customers tc ON ti.total_sales > (
        SELECT AVG(total_sales) FROM top_items
    )
GROUP BY ti.i_product_name, ti.i_brand, tc.c_first_name, tc.c_last_name, tc.cd_gender
ORDER BY total_profit DESC
LIMIT 50;
