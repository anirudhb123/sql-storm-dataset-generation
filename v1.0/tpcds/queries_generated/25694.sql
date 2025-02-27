
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
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
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_size
    FROM 
        item i
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        id.i_product_name,
        id.i_brand,
        id.i_category
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    JOIN 
        ItemDetails id ON ws.ws_item_sk = id.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 30
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    SUM(ws_sales_price * ws_quantity) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_count,
    STRING_AGG(DISTINCT CONCAT(i_brand, ' - ', i_product_name), '; ') AS purchased_items
FROM 
    SalesData
GROUP BY 
    full_name, ca_city, ca_state
ORDER BY 
    total_sales DESC
LIMIT 100;
