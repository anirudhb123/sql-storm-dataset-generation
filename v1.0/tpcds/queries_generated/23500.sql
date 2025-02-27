
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) as rn
    FROM customer_address
), 
item_profit AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS catalog_net_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS store_net_profit,
        COALESCE(SUM(ws.ws_net_profit), 0) + COALESCE(SUM(cs.cs_net_profit), 0) + COALESCE(SUM(ss.ss_net_profit), 0) AS combined_net_profit
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
), 
state_category AS (
    SELECT 
        ca.ca_state,
        CASE 
            WHEN id.total_net_profit > 10000 THEN 'High Profit'
            WHEN id.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM address_cte ca
    JOIN item_profit id ON ca.rn = (SELECT MAX(rn) FROM address_cte WHERE ca_state = ca.ca_state)
    GROUP BY ca.ca_state, id.total_net_profit
)
SELECT 
    sc.ca_state, 
    sc.profit_category, 
    COUNT(DISTINCT ca.ca_city) AS distinct_cities, 
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM state_category sc
LEFT JOIN customer_address ca ON ca.ca_state = sc.ca_state
LEFT JOIN item_profit i ON i.total_net_profit > 0
GROUP BY sc.ca_state, sc.profit_category
ORDER BY sc.ca_state DESC, sc.profit_category;
