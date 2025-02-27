
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, 0 AS level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    
    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    STRING_AGG(DISTINCT t.t_shift) AS unique_shifts,
    CASE 
        WHEN SUM(ws.ws_net_paid) IS NULL THEN 'No Sales'
        ELSE 'Sales Available' 
    END AS sales_status
FROM 
    web_sales ws
JOIN 
    CustomerHierarchy ch ON ws.ws_bill_customer_sk = ch.c_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = ch.c_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    time_dim t ON t.t_time_sk = ws.ws_sold_time_sk
WHERE 
    d.d_year = 2023 
    AND (ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL)
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    unique_customers DESC, total_quantity DESC
LIMIT 10;
