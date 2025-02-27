
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 5000
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
),
customer_address_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS state_rank
    FROM 
        customer_address AS ca
)
SELECT 
    sh.c_customer_id,
    sh.total_net_profit,
    sh.total_orders,
    cad.ca_city,
    cad.ca_state,
    cad.ca_country
FROM 
    sales_hierarchy AS sh
LEFT JOIN 
    customer_address_data AS cad ON sh.c_customer_sk = cad.ca_address_sk
WHERE 
    cad.state_rank <= 5
ORDER BY 
    sh.total_net_profit DESC, 
    cad.ca_city ASC
UNION ALL
SELECT 
    'Total' AS c_customer_id,
    SUM(total_net_profit) AS total_net_profit,
    SUM(total_orders) AS total_orders,
    NULL AS ca_city,
    NULL AS ca_state,
    NULL AS ca_country
FROM 
    sales_hierarchy
HAVING 
    COUNT(*) > 0;
