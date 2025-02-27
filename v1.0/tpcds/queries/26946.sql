
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS average_profit,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotional_offers
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
    ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    average_profit DESC
LIMIT 10;
