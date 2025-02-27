
SELECT 
    ca.city AS address_city,
    cd.gender AS customer_gender,
    dd.year AS order_year,
    SUM(ws.net_paid) AS total_sales
FROM 
    web_sales ws
JOIN 
    customer c ON ws.bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim dd ON ws.sold_date_sk = dd.d_date_sk
WHERE 
    dd.year = 2023
GROUP BY 
    ca.city, cd.gender, dd.year
ORDER BY 
    total_sales DESC;
