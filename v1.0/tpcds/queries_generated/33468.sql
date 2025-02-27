
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_cdemo_sk,
           c_current_addr_sk,
           1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.level < 5
),
total_sales AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws_bill_customer_sk
),
sales_stats AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(ts.total_sales, 0) AS total_sales,
           CASE 
               WHEN COALESCE(ts.total_sales, 0) < 1000 THEN 'Low'
               WHEN COALESCE(ts.total_sales, 0) BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS sales_category
    FROM customer c
    LEFT JOIN total_sales ts ON c.c_customer_sk = ts.customer_sk
),
store_sales_summary AS (
    SELECT ss_store_sk,
           SUM(ss_net_paid) AS total_net_paid
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ss_store_sk
)
SELECT sh.customer_name,
       sh.total_sales,
       st.total_net_paid,
       COALESCE(s.total_sales, 0) AS sales_total,
       CASE 
           WHEN s.sales_category = 'High' THEN 'Preferred Customer'
           ELSE 'Regular Customer'
       END AS customer_status
FROM (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
           ts.total_sales,
           s.sales_category
    FROM sales_stats s
    JOIN customer_hierarchy ch ON s.c_customer_sk = ch.c_customer_sk
    JOIN customer c ON c.c_customer_sk = ch.c_customer_sk
) sh
LEFT JOIN store_sales_summary st ON sh.c_customer_sk = st.ss_store_sk
WHERE sh.total_sales > 0
ORDER BY sh.total_sales DESC
LIMIT 100;
