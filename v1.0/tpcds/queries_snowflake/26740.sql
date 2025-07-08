
SELECT 
    ca.ca_city AS city, 
    ca.ca_state AS state, 
    COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count, 
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate, 
    LISTAGG(DISTINCT i.i_brand, ', ') WITHIN GROUP (ORDER BY i.i_brand) AS brands, 
    LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions
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
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
AND 
    cd.cd_marital_status = 'M'
AND 
    d.d_month_seq BETWEEN 1 AND 12
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    customer_count DESC
LIMIT 10;
