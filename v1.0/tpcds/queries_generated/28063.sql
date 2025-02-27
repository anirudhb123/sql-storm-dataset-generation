
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    GROUP_CONCAT(DISTINCT i.i_product_name ORDER BY i.i_product_name ASC SEPARATOR ', ') AS purchased_products,
    CASE 
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender,
    cd.cd_marital_status,
    d.d_year,
    d.d_month_seq,
    DATE_FORMAT(d.d_date, '%Y-%m-%d') AS purchase_date,
    GROUP_CONCAT(DISTINCT CONCAT(sm.sm_carrier, ' via ', sm.sm_type) ORDER BY sm.sm_carrier ASC SEPARATOR ', ') AS shipping_methods
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
JOIN 
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_sk, ca.ca_city, ca.ca_state, gender, cd.cd_marital_status, d.d_year, d.d_month_seq, purchase_date
ORDER BY 
    total_spent DESC
LIMIT 100;
