
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    d.d_date AS purchase_date,
    i.i_item_desc,
    COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_returns,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk) AS total_web_returns
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON d.d_date_sk = ss.ss_sold_date_sk OR d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    item i ON i.i_item_sk = ss.ss_item_sk OR i.i_item_sk = ws.ws_item_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_date, 
    i.i_item_desc
ORDER BY 
    total_spent DESC, full_name;
