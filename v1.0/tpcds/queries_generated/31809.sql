
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 
           1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
combined_summary AS (
    SELECT
        cs.c_customer_sk,
        cs.order_count,
        cs.total_sales,
        cs.avg_order_value,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value
    FROM sales_summary cs
    LEFT JOIN returns_summary rs ON cs.ws_bill_customer_sk = rs.customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    cs.order_count,
    cs.total_sales,
    cs.avg_order_value,
    cs.total_returns,
    cs.total_return_value
FROM customer_hierarchy ch
LEFT JOIN combined_summary cs ON ch.c_customer_sk = cs.c_customer_sk
WHERE cs.total_sales > 1000
ORDER BY cs.total_sales DESC
LIMIT 100;
