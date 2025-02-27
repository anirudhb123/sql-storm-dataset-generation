
WITH RECURSIVE category_hierarchy AS (
    SELECT i_category_id, i_category, 0 AS depth
    FROM item
    WHERE i_category_id IS NOT NULL
    UNION ALL
    SELECT i.i_category_id, i.i_category, ch.depth + 1
    FROM item i
    JOIN category_hierarchy ch ON i.i_category_id = ch.i_category_id
),
customer_returns AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_return_value,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returned,
        cr.total_return_value,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_value DESC) AS rn
    FROM customer c
    JOIN customer_returns cr ON c.c_customer_sk = cr.c_customer_sk
    WHERE cr.return_count > 0
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name || ' ' || tc.c_last_name AS customer_full_name,
    ch.i_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS avg_profit
FROM top_customers tc
JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN category_hierarchy ch ON i.i_category_id = ch.i_category_id
WHERE wc.ws_sold_date_sk BETWEEN 2459045 AND 2459047
GROUP BY tc.c_customer_sk, tc.c_first_name, tc.c_last_name, ch.i_category
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 10;

