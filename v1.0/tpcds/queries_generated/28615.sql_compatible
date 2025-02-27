
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_quantity) AS total_items
    FROM 
        web_sales ws
    WHERE 
        EXISTS (SELECT 1 FROM customer_info ci WHERE ci.c_customer_id = ws.ws_bill_customer_sk)
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_items,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    rs.ws_order_number,
    rs.ws_item_sk,
    rs.total_sales,
    rs.total_items,
    rs.sales_rank
FROM 
    customer_info ci
JOIN 
    ranked_sales rs ON ci.c_customer_id = rs.ws_order_number
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    ci.ca_state, ci.ca_city, rs.total_sales DESC;
