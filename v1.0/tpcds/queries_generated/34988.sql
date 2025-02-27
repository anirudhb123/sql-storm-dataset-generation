
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_profit) > 1000

    UNION ALL

    SELECT sh.c_customer_sk, sh.c_first_name, sh.c_last_name, 
           SUM(ws.ws_net_profit)
    FROM SalesHierarchy sh
    JOIN web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name
)
SELECT DISTINCT 
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    AVG(ws.ws_net_paid) OVER (PARTITION BY ca.ca_state ORDER BY COUNT(*)) AS avg_order_value,
    SUM(CASE WHEN hd.hd_buy_potential = 'High' THEN cs.cs_quantity ELSE 0 END) AS high_buying_customers
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE ca.ca_state IS NOT NULL 
  AND ca.ca_city IS NOT NULL
  AND (ws.ws_net_profit IS NOT NULL OR cs.cs_net_profit IS NOT NULL)
GROUP BY ca.ca_state, ca.ca_city
ORDER BY total_orders DESC
LIMIT 10;
