
WITH RECURSIVE Sales_Stats AS (
    SELECT 
        ws.customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rn
    FROM 
        web_sales AS ws 
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.customer_sk
),
Top_Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.total_net_profit,
        ss.total_orders
    FROM 
        Sales_Stats ss
    JOIN 
        customer c ON ss.customer_sk = c.c_customer_sk
    WHERE 
        ss.rn <= 10
),
Address_Info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city IS NOT NULL
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country,
    CASE 
        WHEN tc.total_net_profit > 10000 THEN 'High Value'
        WHEN tc.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    Top_Customers tc
LEFT JOIN 
    Address_Info ai ON tc.c_customer_id = ai.ca_address_sk  -- Example of an outer join
ORDER BY 
    tc.total_net_profit DESC;
