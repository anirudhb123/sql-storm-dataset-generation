
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    d.d_date AS order_date,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS order_count,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_items,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    d.d_year = 2023 AND
    cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_sk, full_name, full_address, order_date, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_spent DESC 
LIMIT 10;
