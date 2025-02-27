
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
    UNION ALL
    SELECT
        ss_ship_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_ship_date_sk, ss_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MAX(ws_net_paid_inc_tax) AS max_order_value,
        MIN(ws_net_paid_inc_tax) AS min_order_value,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT
        c.customer_id,
        cs.total_orders,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.avg_order_value DESC) AS rank
    FROM customer_stats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    tc.customer_id,
    tc.total_orders,
    tc.avg_order_value,
    COALESCE(SUM(ss.total_profit), 0) AS total_sales_profit
FROM top_customers tc
JOIN customer_address ca ON tc.customer_id = ca.ca_address_id
LEFT JOIN sales_summary ss ON tc.customer_id = CAST(ss.ws_item_sk AS char)
WHERE ca.ca_state IS NOT NULL
AND (tc.avg_order_value > 100 OR tc.total_orders > 10)
GROUP BY ca.ca_city, ca.ca_state, tc.customer_id, 
         tc.total_orders, tc.avg_order_value
ORDER BY total_sales_profit DESC
LIMIT 50;
