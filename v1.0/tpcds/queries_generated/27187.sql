
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ', ' || ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    AVG(ws.ws_net_profit) AS average_profit_per_order
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_country = 'USA'
    AND d_current_year = 2023
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_spent DESC
LIMIT 100;
