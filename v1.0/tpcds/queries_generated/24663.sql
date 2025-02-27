
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
  UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_zip
    FROM customer_address a
    JOIN address_cte cte ON a.ca_state = cte.ca_state AND a.ca_city <> cte.ca_city
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           cd.cd_marital_status, cd.cd_purchase_estimate,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_sales_price) AS total_sales, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - interval '30 days' FROM date_dim)
    GROUP BY ws.ws_item_sk
),
item_performance AS (
    SELECT i.i_item_sk, i.i_product_name, COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.order_count, 0) AS order_count,
           RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT ai.ca_state, ai.ca_city,
       (SELECT COUNT(DISTINCT c.c_customer_sk) 
        FROM customer_info c 
        WHERE c.rank_gender = 1 AND c.c_first_name IS NOT NULL) AS active_customers,
       SUM(ip.total_sales) AS total_item_sales,
       SUM(ip.order_count) AS total_orders,
       STRING_AGG(DISTINCT ip.i_product_name, ', ') AS featured_products
FROM address_cte ai
LEFT JOIN item_performance ip ON ip.total_sales > 1000
WHERE EXISTS (SELECT 1 
              FROM customer_info ci 
              WHERE ci.c_customer_sk IN 
                    (SELECT DISTINCT ws_bill_customer_sk 
                     FROM web_sales 
                     WHERE ws_ship_addr_sk = ai.ca_address_sk))
GROUP BY ai.ca_state, ai.ca_city
ORDER BY total_item_sales DESC
LIMIT 5;
