
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city AS customer_city,
    ca.ca_state AS customer_state,
    cd.cd_marital_status,
    cd.cd_gender,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS order_count,
    MAX(d.d_date) AS last_purchase_date,
    GROUP_CONCAT(DISTINCT i.i_item_desc ORDER BY i.i_item_desc SEPARATOR '; ') AS purchased_items
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
    d.d_year = 2023
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, 
    ca.ca_city, ca.ca_state, cd.cd_marital_status, cd.cd_gender
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
