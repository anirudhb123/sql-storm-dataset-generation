
SELECT 
    c.c_customer_id, 
    COUNT(DISTINCT sr.ticket_number) AS return_count,
    SUM(sr.return_amt_inc_tax) AS total_return_amount,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender,
    SUM(ws.net_profit) AS total_sales_profit 
FROM 
    customer c
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_id, 
    gender
ORDER BY 
    total_sales_profit DESC;
