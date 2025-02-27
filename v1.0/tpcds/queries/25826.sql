
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(i.i_current_price) AS highest_item_price,
    MIN(i.i_current_price) AS lowest_item_price,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS item_descriptions,
    d.d_month_seq,
    d.d_year
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
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    customer_full_name, ca.ca_city, ca.ca_state, cd.cd_gender, d.d_month_seq, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
