
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_label
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
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
        ROW_NUMBER() OVER (ORDER BY is.total_sales DESC) AS rank
    FROM 
        item i
    JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.gender_label,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_orders
FROM 
    customer_data cd
JOIN 
    top_items ti ON cd.cd_income_band_sk BETWEEN 1 AND 5
WHERE 
    ti.rank <= 10
ORDER BY 
    cd.ca_city, ti.total_sales DESC;
