
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           ws.ws_net_profit, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_net_profit IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_profit) AS ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_net_profit IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    a.ca_state, 
    COUNT(DISTINCT sh.c_customer_sk) AS total_customers,
    SUM(CASE WHEN sh.rank_profit = 1 THEN sh.ws_net_profit ELSE 0 END) AS highest_profit,
    (SELECT AVG(inv.inv_quantity_on_hand) 
     FROM inventory inv 
     WHERE inv.inv_warehouse_sk IN 
        (SELECT w.w_warehouse_sk FROM warehouse w 
         WHERE w.w_country = 'USA'
         AND w.w_state = a.ca_state)) AS avg_quantity_on_hand,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_state = a.ca_state 
       AND s.s_number_employees IS NOT NULL) AS active_stores,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT sh.c_customer_sk) DESC) AS state_rank
FROM customer_address a
LEFT JOIN SalesHierarchy sh ON a.ca_address_sk = sh.c_customer_sk
LEFT JOIN store s ON a.ca_address_sk = s.s_store_sk
GROUP BY a.ca_state
HAVING COUNT(DISTINCT sh.c_customer_sk) > 100
   OR (COUNT(DISTINCT sh.c_customer_sk) IS NULL AND avg_quantity_on_hand > 50)
ORDER BY state_rank, a.ca_state;
