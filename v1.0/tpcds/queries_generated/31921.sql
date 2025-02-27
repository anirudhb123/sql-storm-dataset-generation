
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_preferred_cust_flag,
           1 AS level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_summary AS (
    SELECT ws.web_site_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_sk
),
return_summary AS (
    SELECT sr_returning_customer_sk,
           SUM(sr_return_amt_inc_tax) AS total_returns,
           COUNT(sr_return_quantity) AS return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
combined_stats AS (
    SELECT ch.c_customer_sk,
           ch.c_first_name,
           ch.c_last_name,
           COALESCE(ss.total_sales, 0) AS total_sales,
           COALESCE(rs.total_returns, 0) AS total_returns,
           (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_amount,
           MAX(ch.level) AS hierarchy_level
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.web_site_sk
    LEFT JOIN return_summary rs ON ch.c_customer_sk = rs.sr_returning_customer_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name
)
SELECT c.c_customer_sk,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       cs.total_sales,
       cs.total_returns,
       cs.net_amount,
       CASE 
           WHEN cs.net_amount > 1000 THEN 'High Value'
           WHEN cs.net_amount BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value_segment,
       ROW_NUMBER() OVER (PARTITION BY cs.hierarchy_level ORDER BY cs.net_amount DESC) AS rank
FROM combined_stats cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE cs.hierarchy_level = (SELECT MAX(level) FROM customer_hierarchy)
ORDER BY cs.net_amount DESC
LIMIT 10;
