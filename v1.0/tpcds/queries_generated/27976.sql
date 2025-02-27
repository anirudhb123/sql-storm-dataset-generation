
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        d.d_date AS registration_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_sales,
        is.total_orders,
        RANK() OVER (ORDER BY is.total_sales DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_orders
FROM 
    customer_info ci
JOIN 
    top_items ti ON ti.sales_rank <= 10
WHERE 
    ci.cd_gender = 'F' AND
    ci.cd_education_status LIKE '%Bachelor%' AND
    ci.cd_purchase_estimate > 5000
ORDER BY 
    ti.total_sales DESC, 
    ci.full_name;
