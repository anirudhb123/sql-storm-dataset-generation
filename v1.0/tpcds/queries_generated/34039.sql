
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year,
           NULL AS parent_customer_sk
    FROM customer
    WHERE c_birth_year IS NOT NULL

    UNION ALL

    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year,
           ch.c_customer_sk AS parent_customer_sk
    FROM customer AS c
    JOIN customer_hierarchy AS ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
sales_summary AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           MAX(ws.ws_sales_price) AS max_sales_price,
           MIN(ws.ws_sales_price) AS min_sales_price,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales AS ws
    JOIN date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
customer_returns AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returned,
           SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
combined_sales AS (
    SELECT ss.ss_item_sk AS item_sk, 
           SUM(ss.ss_quantity) AS total_store_sales,
           COALESCE(cr.total_returned, 0) AS total_returns,
           COALESCE(cr.total_returned_amt, 0) AS return_amount
    FROM store_sales AS ss
    LEFT JOIN customer_returns AS cr ON ss.ss_item_sk = cr.sr_item_sk
    GROUP BY ss.ss_item_sk
)
SELECT ch.c_first_name,
       ch.c_last_name,
       ch.c_birth_year,
       ss.total_quantity,
       cs.total_store_sales,
       ss.max_sales_price,
       ss.min_sales_price,
       ss.avg_sales_price,
       cs.total_returns,
       cs.return_amount
FROM customer_hierarchy AS ch
JOIN sales_summary AS ss ON ch.c_customer_sk = ss.ws_item_sk
JOIN combined_sales AS cs ON ss.ws_item_sk = cs.item_sk
WHERE ch.c_birth_year < (SELECT AVG(c_birth_year) FROM customer) 
      AND ss.total_quantity > (
          SELECT AVG(total_quantity) 
          FROM sales_summary
      )
ORDER BY ch.c_birth_year DESC;
