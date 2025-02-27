
WITH RECURSIVE sales_relations AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk, 
        ws_item_sk
)
SELECT 
    ca.city,
    ca.state,
    ca.country,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(COALESCE(s.total_profit, 0)) AS total_profit,
    AVG(COALESCE(s.total_profit, 0)) AS avg_profit_per_customer
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_relations s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1990 AND 2000
    AND s.rnk <= 5
GROUP BY 
    ca.city, ca.state, ca.country
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    total_profit DESC
LIMIT 10;
