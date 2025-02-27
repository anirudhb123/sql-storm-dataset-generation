
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    cd.gender AS customer_gender,
    cd.education_status AS customer_education,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(ws.net_profit) AS total_net_profit,
    AVG(i.current_price) AS average_item_price,
    STRING_AGG(DISTINCT w.warehouse_name, ', ') AS warehouses,
    d.year AS sale_year,
    d.month AS sale_month,
    d.day_name AS sale_day_name
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.gender = 'F' 
    AND d.year = 2023 
    AND d.moy IN (5, 6, 7)  -- May, June, July
GROUP BY 
    ca.city, ca.state, cd.gender, cd.education_status, d.year, d.month, d.day_name
ORDER BY 
    total_net_profit DESC, address_city;
