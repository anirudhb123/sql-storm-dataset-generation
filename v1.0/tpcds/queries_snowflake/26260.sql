
SELECT 
    CONCAT(COALESCE(c.c_salutation, ''), ' ', c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type || 
    CASE WHEN ca.ca_suite_number IS NOT NULL THEN ' Suite ' || ca.ca_suite_number ELSE '' END AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    d.d_date AS purchase_date,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    LISTAGG(DISTINCT wp.wp_url, ', ') WITHIN GROUP (ORDER BY wp.wp_url) AS visited_web_pages
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    web_page AS wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_sk, c.c_salutation, c.c_first_name, c.c_last_name, 
    ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number,
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_date
ORDER BY 
    total_spent DESC
LIMIT 10;
