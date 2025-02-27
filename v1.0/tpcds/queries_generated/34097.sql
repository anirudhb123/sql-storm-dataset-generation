
WITH RECURSIVE sales_analysis AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs_order_number,
        cs_item_sk,
        cs_net_profit,
        level + 1
    FROM 
        catalog_sales cs
    WHERE 
        cs_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023))
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(COALESCE(sa.ws_net_profit, 0)) AS total_web_sales_profit,
    SUM(COALESCE(sa.cs_net_profit, 0)) AS total_catalog_sales_profit,
    COUNT(DISTINCT sa.ws_order_number) AS total_orders,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(COALESCE(sa.ws_net_profit, 0)) DESC) AS city_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_analysis sa ON c.c_customer_sk = sa.ws_item_sk OR c.c_customer_sk = sa.cs_item_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(COALESCE(sa.ws_net_profit, 0)) > 5000
ORDER BY 
    city_rank,
    total_web_sales_profit DESC;
