
SELECT 
    ca.city AS address_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(CASE 
            WHEN cd.cd_gender = 'M' THEN ws.ws_net_profit 
            ELSE NULL 
        END) AS avg_male_net_profit,
    AVG(CASE 
            WHEN cd.cd_gender = 'F' THEN ws.ws_net_profit 
            ELSE NULL 
        END) AS avg_female_net_profit,
    STRING_AGG(DISTINCT cd.cd_marital_status, ', ') AS marital_status_list,
    DATE_PART('year', d.d_date) AS sale_year,
    COUNT(DISTINCT CASE 
            WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_order_number 
            END) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA'
    AND d.d_date >= '2023-01-01' 
    AND d.d_date < '2024-01-01'
GROUP BY 
    ca.city, sale_year
ORDER BY 
    total_net_profit DESC;
