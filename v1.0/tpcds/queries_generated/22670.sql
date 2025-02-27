
WITH ranked_sales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
customer_orders AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id
),
promotions AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_promo_revenue
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    co.total_orders,
    co.total_spent,
    ps.promo_name,
    ps.total_promo_revenue,
    MAX(rs.ws_net_profit) AS max_net_profit,
    AVG(COALESCE(rs.ws_net_profit, 0)) AS avg_net_profit
FROM customer_orders co
JOIN ranked_sales rs ON co.total_orders > 0
LEFT JOIN customer_address ca ON co.c_customer_id = ca.ca_address_id
LEFT JOIN promotions ps ON ps.total_promo_revenue > 1000
WHERE (ca.ca_country IS NULL OR ca.ca_country != 'USA')
AND co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
GROUP BY ca.ca_city, ca.ca_state, ps.promo_name
HAVING COUNT(co.c_customer_id) > 5
ORDER BY avg_net_profit DESC
LIMIT 10;
