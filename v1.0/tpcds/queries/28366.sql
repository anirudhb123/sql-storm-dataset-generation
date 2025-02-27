
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_street_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ': $', i.i_current_price), '; ') AS purchased_items
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND cd.cd_credit_rating = 'High'
    AND ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
ORDER BY 
    total_spent DESC
LIMIT 100;
