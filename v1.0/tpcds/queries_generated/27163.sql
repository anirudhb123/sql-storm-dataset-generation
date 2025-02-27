
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ci.customer_full_name,
        ii.i_item_id,
        ii.i_item_desc
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    JOIN 
        ItemInfo ii ON ws.ws_item_sk = ii.i_item_id
),
AggregatedSales AS (
    SELECT 
        customer_full_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        SalesInfo
    GROUP BY 
        customer_full_name
)
SELECT 
    customer_full_name,
    total_orders,
    total_quantity,
    total_sales,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    AggregatedSales
ORDER BY 
    total_sales DESC
LIMIT 10;
