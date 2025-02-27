
SELECT 
    ca.city AS customer_city,
    cd.cd_gender AS customer_gender,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_net_profit,
    EXTRACT(YEAR FROM d.d_date) AS sales_year
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
    AND cd.cd_marital_status = 'M'
GROUP BY 
    ca.city, 
    cd.cd_gender, 
    EXTRACT(YEAR FROM d.d_date)
ORDER BY 
    sales_year DESC, 
    total_sales DESC
LIMIT 100;
