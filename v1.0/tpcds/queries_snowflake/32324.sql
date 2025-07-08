
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS hierarchy_level,
        c.c_current_cdemo_sk
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y'

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.hierarchy_level + 1,
        c.c_current_cdemo_sk
    FROM 
        customer c
    INNER JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)

SELECT 
    ca.ca_city AS customer_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
    AVG(ws.ws_net_paid) AS avg_transaction_value,
    MAX(ws.ws_sold_date_sk) AS last_transaction_date,
    MIN(CASE WHEN ws.ws_net_paid < 0 THEN 1 ELSE NULL END) AS return_count,
    RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_profit) DESC) AS city_profit_rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND (c.c_birth_year < 1990 OR c.c_current_cdemo_sk IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 5
ORDER BY 
    total_profit DESC
LIMIT 10;
