
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk >= 2400 -- hypothetical date range for performance
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk < 2400
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
)

SELECT 
    ca.ca_city,
    SUM(sh.total_profit) AS city_total_profit,
    COUNT(DISTINCT sh.c_customer_sk) AS unique_customers,
    MAX(sh.total_profit) AS max_profit,
    MIN(sh.total_profit) AS min_profit,
    AVG(sh.total_profit) AS avg_profit,
    CASE 
        WHEN AVG(sh.total_profit) IS NULL THEN 'No Profit'
        ELSE CAST(AVG(sh.total_profit) AS VARCHAR(20))
    END AS avg_profit_string
FROM 
    sales_hierarchy sh
JOIN 
    customer_address ca ON sh.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim d ON d.d_date_sk = sh.ss_sold_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    ca.ca_city
ORDER BY 
    city_total_profit DESC
LIMIT 10;

-- Additional set operation between web_sales and street address information
SELECT 
    ca.ca_state,
    COUNT(ws.ws_order_number) AS web_sales_count,
    SUM(ws.ws_net_profit) AS total_web_profit
FROM 
    web_sales ws
JOIN 
    customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA'
GROUP BY 
    ca.ca_state
HAVING 
    SUM(ws.ws_net_profit) > 1000
UNION ALL
SELECT 
    ca.ca_state,
    0 AS web_sales_count,
    SUM(sr_return_amt) AS total_web_profit
FROM 
    store_returns sr
JOIN 
    customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA'
GROUP BY 
    ca.ca_state
HAVING 
    SUM(sr_return_amt) < 500;
