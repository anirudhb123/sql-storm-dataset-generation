
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
item_prices AS (
    SELECT i_item_sk, i_product_name, i_current_price,
           ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_current_price DESC) AS price_rank
    FROM item
    WHERE i_current_price IS NOT NULL
),
sales_summary AS (
    SELECT ws_bill_cdemo_sk AS demo_sk,
           SUM(ws_net_paid_inc_tax) AS total_sales,
           AVG(ws_quantity) AS avg_quantity,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2400 AND 2800
    GROUP BY ws_bill_cdemo_sk
),
returns_summary AS (
    SELECT sr_cdemo_sk AS demo_sk,
           SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    GROUP BY sr_cdemo_sk
),
combined_summary AS (
    SELECT ss.demo_sk,
           COALESCE(ss.total_sales, 0) AS total_sales,
           COALESCE(rs.total_returns, 0) AS total_returns,
           ss.avg_quantity,
           ss.order_count
    FROM sales_summary ss
    LEFT JOIN returns_summary rs ON ss.demo_sk = rs.demo_sk
)
SELECT ch.c_first_name, ch.c_last_name, ch.c_preferred_cust_flag,
       cs.total_sales, cs.total_returns, cs.avg_quantity, cs.order_count,
       ip.i_product_name, ip.i_current_price
FROM customer_hierarchy ch
JOIN combined_summary cs ON ch.c_current_cdemo_sk = cs.demo_sk
JOIN item_prices ip ON cs.total_sales > 0
WHERE (ch.c_preferred_cust_flag = 'Y' OR ch.c_preferred_cust_flag IS NULL)
AND (ch.level = 1 OR EXISTS (SELECT 1 FROM combined_summary WHERE total_sales > 1000))
ORDER BY cs.total_sales DESC, ch.c_last_name ASC 
LIMIT 100;
