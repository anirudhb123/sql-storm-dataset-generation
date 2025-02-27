WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_market_id,
        s_division_id,
        1 AS level
    FROM store
    WHERE s_store_id = 'S1'
    
    UNION ALL
    
    SELECT 
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_market_id,
        s.s_division_id,
        sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_division_id = sh.s_division_id 
    WHERE sh.level < 5
), 
sales_summary AS (
    SELECT 
        h.s_store_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM sales_hierarchy h
    LEFT JOIN web_sales ws ON h.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY h.s_store_id
),
top_sales AS (
    SELECT 
        s.s_store_id,
        s.total_net_profit,
        RANK() OVER (ORDER BY s.total_net_profit DESC) AS rn
    FROM sales_summary s
)
SELECT 
    t.s_store_id,
    t.total_net_profit,
    th.s_store_name,
    (SELECT COUNT(*) 
     FROM customer_address ca 
     LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk 
     WHERE ca.ca_city = 'Los Angeles' 
     AND c.c_customer_id IS NOT NULL) AS los_angeles_customers,
    (SELECT MAX(age) 
     FROM (
         SELECT 
             EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year AS age
         FROM customer c 
         WHERE c.c_birth_country IS NOT NULL
         ) AS customer_ages) AS max_customer_age
FROM top_sales t
JOIN store th ON t.s_store_id = th.s_store_id
WHERE t.rn <= 10
ORDER BY t.total_net_profit DESC;