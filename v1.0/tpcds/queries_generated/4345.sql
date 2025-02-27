
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.web_site_sk,
        ws.shipping_date_sk,
        SUM(ws.net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.bill_customer_sk, ws.web_site_sk, ws.shipping_date_sk
),
MaxProfit AS (
    SELECT 
        bill_customer_sk,
        MAX(total_net_profit) AS max_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
    GROUP BY 
        bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(a.ca_city, 'Unknown') AS city,
    mp.max_profit
FROM 
    customer c
LEFT JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    MaxProfit mp ON c.c_customer_sk = mp.bill_customer_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
AND 
    a.ca_state IS NOT NULL
ORDER BY 
    mp.max_profit DESC
LIMIT 10;
