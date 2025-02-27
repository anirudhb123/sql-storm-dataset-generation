
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ws_net_paid) AS total_sales,
    AVG(cd_credit_rating) AS avg_credit_rating,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(CASE WHEN ws_net_paid > 100 THEN ws_net_paid END) AS avg_high_value_sales
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
