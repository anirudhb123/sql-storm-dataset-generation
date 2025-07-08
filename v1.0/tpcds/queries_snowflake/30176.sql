
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_salutation = 'Mr.' AND ch.level < 10
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_credit_rating, 
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 100000
),
filtered_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_order_number, ws.ws_item_sk
)
SELECT 
    f.ws_order_number,
    f.total_quantity,
    f.total_revenue,
    h.full_name,
    ss.total_sales,
    ss.order_count,
    ss.avg_profit,
    COALESCE(r.r_reason_desc, 'No Reason Provided') AS return_reason
FROM filtered_sales f
JOIN high_value_customers h ON f.ws_item_sk = h.c_customer_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = f.ws_order_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN sales_summary ss ON ss.w_warehouse_id = (SELECT MAX(w_warehouse_id) FROM warehouse)
WHERE f.total_quantity > 5
ORDER BY f.total_revenue DESC
LIMIT 100;
