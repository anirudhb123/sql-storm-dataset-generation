
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(is.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(is.total_sales_value, 0) AS total_sales_value
    FROM 
        item i
    LEFT JOIN 
        ItemSales is ON i.i_item_sk = is.ws_item_sk
),
TopItems AS (
    SELECT 
        pi.i_item_id,
        pi.i_item_desc,
        pi.total_sales_quantity,
        pi.total_sales_value,
        RANK() OVER (ORDER BY pi.total_sales_value DESC) AS sales_rank
    FROM 
        PopularItems pi
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_sales_quantity,
    ti.total_sales_value
FROM 
    CustomerInfo ci
JOIN 
    TopItems ti ON ti.sales_rank <= 10
ORDER BY 
    ci.ca_state, ti.total_sales_value DESC;
