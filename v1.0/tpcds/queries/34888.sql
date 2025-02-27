
WITH RECURSIVE customer_tree AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        c_current_cdemo_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        c.c_current_cdemo_sk,
        ct.level + 1
    FROM 
        customer AS c
    JOIN customer_tree AS ct ON c.c_current_cdemo_sk = ct.c_customer_sk
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT ct.full_name) AS customer_count,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_net_profit) AS average_net_profit,
    MAX(ws.ws_net_paid) AS max_paid,
    MIN(ws.ws_net_paid) AS min_paid,
    CASE 
        WHEN MAX(ws.ws_net_paid) > 1000 THEN 'High Value'
        WHEN MAX(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COALESCE(SUM(ws.ws_ext_discount_amt), 0) AS total_discount
FROM 
    customer_address AS ca
LEFT JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_tree AS ct ON ct.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND (ct.level <= 3 OR ct.level IS NULL)
    AND (ws.ws_sold_date_sk BETWEEN 2458849 AND 2458949 OR ws.ws_sold_date_sk IS NULL)
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC, 
    total_quantity_sold DESC
FETCH FIRST 10 ROWS ONLY;
