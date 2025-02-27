
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        regex_replace(c.c_email_address, '@.+$', '@example.com') AS masked_email
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
),
sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 100 
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        si.total_sales,
        si.total_orders,
        RANK() OVER (ORDER BY si.total_sales DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        sales_data si ON i.i_item_sk = si.ws_item_sk
    WHERE 
        length(i.i_product_name) > 20
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ti.i_product_name,
    ti.total_sales,
    ti.total_orders,
    ti.sales_rank
FROM 
    customer_info ci
JOIN 
    top_items ti ON ci.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM sales_data))
ORDER BY 
    ti.sales_rank, 
    ci.full_name;
