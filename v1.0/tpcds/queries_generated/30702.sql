
WITH RECURSIVE sales_tree AS (
    SELECT 
        ws_item_sk,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    UNION ALL
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS net_profit,
        level + 1
    FROM 
        web_sales ws
    JOIN sales_tree st ON ws_item_sk = st.ws_item_sk
    WHERE 
        ws_sold_date_sk < (SELECT MAX(ws_sold_date_sk) FROM web_sales) AND 
        ws_net_profit > 0
    GROUP BY 
        ws_item_sk, level
)
SELECT 
    ca_address.city AS address_city,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    MAX(ws_net_profit) AS max_net_profit,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_tree st ON ws.ws_item_sk = st.ws_item_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ca_address.city
HAVING 
    SUM(ws_net_profit) > 1000 AND
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_net_profit DESC
LIMIT 10;
