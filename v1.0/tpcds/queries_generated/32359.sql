
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_birth_month,
           c_birth_year,
           1 AS level
    FROM customer
    WHERE c_birth_month IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_month,
           c.c_birth_year,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = (SELECT MAX(d_year) FROM date_dim))
    GROUP BY ws.ws_item_sk
),
ranked_sales AS (
    SELECT sd.ws_item_sk,
           sd.total_sales,
           sd.total_orders,
           RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
),
return_data AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
item_performance AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           COALESCE(rs.total_sales, 0) AS total_sales,
           COALESCE(rs.total_orders, 0) AS total_orders,
           COALESCE(rd.total_returns, 0) AS total_returns,
           (COALESCE(rs.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_units
    FROM item i
    LEFT JOIN ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN return_data rd ON i.i_item_sk = rd.sr_item_sk
)
SELECT ch.c_first_name,
       ch.c_last_name,
       ch.c_birth_month,
       ch.c_birth_year,
       SUM(ip.total_sales) AS total_sales,
       SUM(ip.total_orders) AS total_orders,
       AVG(ip.net_units) AS avg_net_units
FROM customer_hierarchy ch
JOIN item_performance ip ON ch.c_customer_sk = ip.i_item_sk
GROUP BY ch.c_first_name, ch.c_last_name, ch.c_birth_month, ch.c_birth_year
HAVING AVG(ip.net_units) > 5
ORDER BY total_sales DESC;
