
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 0 AS depth
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, depth + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ah.depth < 5
),
customer_stats AS (
    SELECT c.c_customer_sk, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
order_stats AS (
    SELECT
        ws.ws_bill_customer_sk,
        COUNT(*) AS online_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_profit, 0) AS total_profit,
    COALESCE(os.online_orders, 0) AS online_orders,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN cs.total_profit > 1000 THEN 'High Value Customer'
        WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY total_profit DESC) AS state_rank
FROM customer_address ca
LEFT JOIN customer_stats cs ON ca.ca_address_sk = cs.c_customer_sk
LEFT JOIN order_stats os ON cs.c_customer_sk = os.ws_bill_customer_sk
WHERE ca.ca_state NOT IN ('NY', 'CA') 
AND (cs.total_orders IS NULL OR cs.total_orders > 5) 
AND (os.total_revenue > 500 OR os.online_orders IS NULL)
ORDER BY ca.ca_city;
