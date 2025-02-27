
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk, level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE level < 5
), sales_summary AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_sales_price) AS total_sales, COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), overall_stats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ss.total_sales) AS total_sales,
        AVG(ss.order_count) AS avg_order_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    GROUP BY ca.ca_state
), rank_states AS (
    SELECT 
        os.ca_state,
        os.customer_count,
        os.total_sales,
        os.avg_order_count,
        RANK() OVER (ORDER BY os.total_sales DESC) AS sales_rank
    FROM overall_stats os
)
SELECT 
    r.ca_state, 
    r.customer_count, 
    r.total_sales, 
    r.avg_order_count,
    COALESCE((
        SELECT COUNT(*)
        FROM store s
        WHERE s.s_state = r.ca_state
    ), 0) AS store_count,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top 10 States by Sales'
        ELSE 'Other States'
    END AS sales_category
FROM rank_states r
WHERE r.customer_count > 100
ORDER BY r.total_sales DESC;
