
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_birth_year < (SELECT MAX(d_year) FROM date_dim WHERE d_current_year = 'Y')
    
    UNION ALL
    
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.ca_address_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status_category
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store s ON ws.ws_store_sk = s.s_store_sk
WHERE 
    ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND ws.ws_net_profit IS NOT NULL
GROUP BY 
    ca.ca_address_id, 
    ca.ca_city, 
    cd.cd_gender, 
    cd.cd_marital_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_net_profit DESC;
