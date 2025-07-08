
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_store_sk, SUM(ss_net_profit) AS total_profit, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
    UNION ALL
    SELECT sh.ss_store_sk, sh.total_profit * 0.9, sh.level + 1
    FROM sales_hierarchy sh
    JOIN store s ON sh.ss_store_sk = s.s_store_sk
    WHERE sh.level < 3
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    SUM(ws.ws_net_profit) AS total_web_profit,
    AVG(ws.ws_net_paid_inc_tax) AS avg_web_net_paid,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    MAX(ws.ws_ship_date_sk) AS latest_ship_date,
    CASE 
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No Profit' 
        ELSE 'Profit Exists'
    END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS state_rank,
    LISTAGG(c.c_email_address, ', ') WITHIN GROUP (ORDER BY c.c_email_address) AS email_list
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.ss_store_sk = ws.ws_warehouse_sk
GROUP BY 
    ca.ca_city, ca.ca_state, ca.ca_country
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_web_profit DESC;
