
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, sh.level + 1
    FROM customer c
    INNER JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
), 
sales_data AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
sales_metrics AS (
    SELECT
        sd.ws_item_sk,
        sd.total_orders,
        sd.total_revenue,
        sd.avg_order_value,
        CASE 
            WHEN sd.total_revenue > (SELECT AVG(total_revenue) FROM sales_data) THEN 'Above Average'
            ELSE 'Below Average'
        END AS revenue_performance,
        COALESCE(COUNT(DISTINCT sr_ticket_number), 0) AS total_returns
    FROM sales_data sd
    LEFT JOIN store_returns sr ON sd.ws_item_sk = sr.sr_item_sk
    GROUP BY sd.ws_item_sk, sd.total_orders, sd.total_revenue, sd.avg_order_value
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sm.ws_item_sk,
    sm.total_orders,
    sm.total_revenue,
    sm.avg_order_value,
    sm.revenue_performance,
    sm.total_returns
FROM sales_metrics sm
JOIN sales_hierarchy sh ON sh.c_customer_sk = sm.ws_item_sk
WHERE sh.level < 3
ORDER BY sm.total_revenue DESC
LIMIT 10;
