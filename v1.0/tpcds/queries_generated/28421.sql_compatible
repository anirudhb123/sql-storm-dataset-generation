
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city || ', ' || ca.ca_state AS address,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    MIN(d.d_date) AS first_purchase_date,
    MAX(d.d_date) AS last_purchase_date,
    COUNT(DISTINCT d.d_date) AS unique_purchase_days,
    TRIM(UPPER(CAST(cd.cd_education_status AS CHAR(20)))) AS education_status,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_returns
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_education_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 
    AND SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC, 
    last_purchase_date DESC;
