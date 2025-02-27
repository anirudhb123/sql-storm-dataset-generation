
WITH RECURSIVE sales_ranking AS (
    SELECT ws_item_sk, ws_order_number, ws_sales_price, ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_position
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451550
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
total_sales AS (
    SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_revenue
    FROM web_sales
    GROUP BY ws_item_sk
),
high_value_sales AS (
    SELECT s.ws_item_sk, s.ws_order_number, s.ws_sales_price, s.ws_net_paid, s.ws_ext_sales_price
    FROM web_sales s
    JOIN total_sales t ON s.ws_item_sk = t.ws_item_sk
    WHERE t.total_revenue > 10000
),
joined_info AS (
    SELECT c.c_first_name, c.c_last_name, s.ws_item_sk, s.ws_order_number, 
           s.ws_sales_price, s.ws_net_paid, s.ws_ext_sales_price,
           RANK() OVER (PARTITION BY s.ws_item_sk ORDER BY s.ws_ext_sales_price DESC) AS value_rank
    FROM high_value_sales s
    JOIN customer_info c ON s.ws_order_number = c.c_customer_sk
)
SELECT j.c_first_name, j.c_last_name, j.ws_item_sk, j.ws_order_number, 
       j.ws_sales_price, j.ws_net_paid, j.ws_ext_sales_price
FROM joined_info j
WHERE j.value_rank <= 10
ORDER BY j.ws_item_sk, j.ws_sales_price DESC;

```
