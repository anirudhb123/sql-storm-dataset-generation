
WITH RECURSIVE sales_summary AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
),
ranked_sales AS (
    SELECT ss_item_sk, 
           total_sales, 
           total_orders, 
           avg_sales_price, 
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           CASE 
               WHEN cd_gender = 'M' THEN 'Male'
               WHEN cd_gender = 'F' THEN 'Female'
               ELSE 'Other' 
           END AS gender,
           cd_marital_status AS marital_status,
           COALESCE(cd_credit_rating, 'Unknown') AS credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT ca_address_sk, 
           ca_city,
           ca_state,
           CA_COUNTRY, 
           DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
)
SELECT ci.c_customer_sk,
       ci.c_first_name,
       ci.c_last_name,
       ci.gender,
       ci.marital_status,
       ci.credit_rating,
       ai.ca_city,
       ai.ca_state,
       ss.total_sales,
       ss.total_orders,
       ss.avg_sales_price,
       CASE 
           WHEN ss.total_sales > 5000 THEN 'High'
           WHEN ss.total_sales > 1000 THEN 'Medium'
           ELSE 'Low' 
       END AS sales_category
FROM ranked_sales ss
JOIN customer_info ci ON ss.ws_item_sk = ci.c_customer_sk
JOIN address_info ai ON ai.ca_address_sk = ci.c_current_addr_sk
LEFT JOIN store_sales ss2 ON ss2.ss_item_sk = ss.ws_item_sk
WHERE (ci.marital_status = 'S' OR ci.gender = 'F') 
  AND (ai.ca_country = 'USA' OR ai.ca_country IS NULL)
  AND ss.sales_rank <= 100
ORDER BY ss.total_sales DESC, ci.c_last_name ASC
LIMIT 50;
