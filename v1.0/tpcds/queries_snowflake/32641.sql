
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_net_profit,
        level + 1
    FROM 
        catalog_sales cs
    INNER JOIN 
        SalesCTE s ON cs.cs_order_number = s.ws_order_number
)

SELECT 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    LISTAGG(DISTINCT c.c_email_address, ', ') WITHIN GROUP (ORDER BY c.c_email_address) AS customer_emails
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    SalesCTE scte ON ws.ws_order_number = scte.ws_order_number
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_country = 'USA'
    AND c.c_birth_year BETWEEN 1970 AND 2000
    AND (scte.ws_sales_price IS NULL OR scte.ws_sales_price > 100)
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_net_profit DESC;
