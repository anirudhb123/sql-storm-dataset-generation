
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    MAX(d.d_date) AS last_purchase_date,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    CASE
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Other'
    END AS marital_status
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    total_spent DESC
LIMIT 10;
