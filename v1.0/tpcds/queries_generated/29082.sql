
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_item_price,
    STRING_AGG(DISTINCT CONCAT(i.i_product_name, ' (', i.i_item_id, ')'), ', ') AS purchased_items,
    DATE_PART('year', d.d_date) AS purchase_year,
    DATE_PART('month', d.d_date) AS purchase_month
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    LOWER(ca.ca_city) LIKE '%boston%' 
    AND cd.cd_gender = 'F' 
    AND d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, c.c_email_address, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_date
ORDER BY 
    total_profit DESC
LIMIT 10;
