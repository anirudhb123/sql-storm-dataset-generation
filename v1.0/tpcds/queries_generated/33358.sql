
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
address_summary AS (
    SELECT ca_state,
           COUNT(DISTINCT c_customer_sk) AS total_customers,
           AVG(ca_gmt_offset) AS avg_gmt_offset,
           SUM(COALESCE(ca_zip, '0')) AS zip_sum
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_state
),
sales_details AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined_data AS (
    SELECT h.c_customer_sk,
           h.c_first_name,
           h.c_last_name,
           a.ca_state,
           a.total_customers,
           a.avg_gmt_offset,
           s.total_sales,
           s.order_count
    FROM customer_hierarchy h
    LEFT JOIN address_summary a ON h.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address)
    LEFT JOIN sales_details s ON h.c_customer_sk = s.ws_bill_customer_sk
)
SELECT *,
       CASE 
           WHEN total_sales IS NULL THEN 'No Sales'
           WHEN total_sales > 10000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_category
FROM combined_data
WHERE total_sales IS NOT NULL
  AND avg_gmt_offset BETWEEN -5.00 AND 0.00
ORDER BY total_sales DESC, c_last_name ASC
LIMIT 50;
