
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.sold_date_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
        AND ws.sold_date_sk >= 2458800 -- Example cutoff date (1st Jan 2020)
    GROUP BY 
        ws.bill_customer_sk, ws.sold_date_sk
),
top_customers AS (
    SELECT 
        bill_customer_sk,
        total_quantity,
        total_profit
    FROM 
        ranked_sales
    WHERE 
        rank <= 10
)
SELECT 
    ca.city,
    ca.state,
    SUM(tc.total_quantity) AS total_quantity,
    SUM(tc.total_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    CASE 
        WHEN SUM(tc.total_profit) > 10000 THEN 'High'
        WHEN SUM(tc.total_profit) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_band
FROM 
    top_customers tc
LEFT JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(tc.total_quantity) > 100
ORDER BY 
    total_profit DESC;
