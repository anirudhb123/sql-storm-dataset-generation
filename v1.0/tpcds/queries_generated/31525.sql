
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        0 AS level,
        CAST(c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM 
        customer c
    WHERE 
        c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        ch.level + 1,
        CAST(c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE 
        ch.level < 5
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(sd.total_profit) AS total_sales_profit,
    AVG(sd.total_orders) AS avg_orders,
    MAX(ch.level) AS max_customer_level
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesData sd ON sd.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    AVG(sd.total_orders) > 1
ORDER BY 
    total_sales_profit DESC
LIMIT 10;

