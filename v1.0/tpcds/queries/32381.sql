
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        1 AS level,
        c_current_cdemo_sk
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1,
        c.c_current_cdemo_sk
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_net_paid,
    STRING_AGG(DISTINCT sm.sm_carrier, ', ') AS carriers_used,
    DATE_PART('year', d.d_date) AS year
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
WHERE 
    d.d_current_year = 'Y'
    AND (ca.ca_city IS NOT NULL AND ca.ca_city <> '')
GROUP BY 
    ca.ca_city,
    DATE_PART('year', d.d_date)
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_net_profit DESC;
