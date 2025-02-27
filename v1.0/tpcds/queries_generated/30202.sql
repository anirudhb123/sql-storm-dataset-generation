
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        0 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        sh.level + 1
    FROM 
        customer AS cs
    JOIN 
        sales_hierarchy AS sh ON cs.c_current_cdemo_sk = sh.c_customer_sk
)
SELECT 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_net_profit) AS max_net_profit,
    MIN(ws.ws_net_paid) AS min_net_paid,
    CASE 
        WHEN COUNT(DISTINCT c.c_customer_id) > 0 THEN SUM(ws.ws_sales_price) / COUNT(DISTINCT c.c_customer_id)
        ELSE 0 
    END AS avg_sales_per_customer,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS state_rank
FROM 
    web_sales AS ws
JOIN 
    customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store AS s ON ws.ws_warehouse_sk = s.s_store_sk
LEFT JOIN 
    (SELECT 
        sr_item_sk, SUM(sr_return_quantity) AS total_returns
     FROM 
        store_returns 
     GROUP BY 
        sr_item_sk
    ) AS sr ON ws.ws_item_sk = sr.sr_item_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 2458153 AND 2458757
    AND c.c_birth_month BETWEEN 6 AND 8
GROUP BY 
    ca.ca_state
HAVING 
    (COUNT(DISTINCT c.c_customer_id) > 10 AND SUM(ws.ws_net_profit) > 1000)
    OR (SUM(sr.total_returns) IS NULL)
ORDER BY 
    total_sales_quantity DESC, state_rank;
