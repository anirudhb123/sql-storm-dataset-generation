
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    LISTAGG(DISTINCT COALESCE(p.p_promo_name, 'No Promo'), ', ') AS promo_names
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_city ILIKE '%town%' 
    AND cd.cd_gender = 'M'
    AND cd.cd_marital_status = 'S'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_spent DESC
LIMIT 10;
