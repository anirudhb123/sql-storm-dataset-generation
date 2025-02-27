
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
    SUBSTRING_INDEX(c.c_email_address, '@', -1) AS email_domain, 
    COUNT(DISTINCT ws.ws_order_number) AS total_online_orders, 
    SUM(ws.ws_sales_price) AS total_spent_online,
    MAX(CONCAT('(', ca.ca_street_number, ') ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip)) AS full_address,
    CASE 
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender,
    DATE_FORMAT(DATE_ADD(MAX(d.d_date), INTERVAL 1 DAY), '%Y-%m-%d') AS next_promo_date
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    cd.cd_marital_status = 'M' AND 
    cd.cd_purchase_estimate > 1000
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender 
HAVING 
    total_spent_online >= 500
ORDER BY 
    total_spent_online DESC
LIMIT 100;
