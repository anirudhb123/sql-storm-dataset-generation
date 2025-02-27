
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    HAVING 
        SUM(ss_net_profit) > 10000
    UNION ALL
    SELECT 
        s.s_store_sk,
        s.ss_net_profit + h.total_profit,
        h.total_transactions + 1,
        h.rank
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy h ON s.ss_store_sk = h.ss_store_sk
    WHERE 
        s.ss_net_profit > 0
)
SELECT
    c.c_customer_id,
    SUM(ws.ws_net_profit) AS total_web_profit,
    MAX(ss.ws_net_profit) AS max_store_profit,
    MIN(COALESCE(ws.ws_net_paid, 0)) AS min_web_paid,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    ARRAY_AGG(DISTINCT ca.ca_city) AS visited_cities
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_last_name LIKE 'S%')
GROUP BY 
    c.c_customer_id
HAVING 
    total_web_profit > 5000
ORDER BY 
    total_web_profit DESC
LIMIT 10;
