
SELECT 
    SUM(ws_net_profit) AS total_net_profit,
    d_year,
    c_gender
FROM 
    web_sales 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk 
JOIN 
    customer_demographics ON ws_bill_cdemo_sk = cd_demo_sk 
GROUP BY 
    d_year, c_gender 
ORDER BY 
    total_net_profit DESC 
LIMIT 10;
