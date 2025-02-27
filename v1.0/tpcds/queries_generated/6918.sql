
SELECT 
    ca.country AS customer_country,
    cd.gender AS customer_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS average_order_value,
    DATE_FORMAT(dd.d_date, '%Y-%m') AS order_month
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
    AND dd.d_month_seq IN (1, 2, 3) -- First quarter
    AND cd.cd_gender IN ('M', 'F') -- Both genders
GROUP BY 
    ca.country, cd.gender, order_month
ORDER BY 
    total_profit DESC, total_orders DESC
LIMIT 100;
