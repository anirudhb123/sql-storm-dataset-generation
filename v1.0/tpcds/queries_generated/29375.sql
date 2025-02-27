
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        LOWER(TRIM(i.i_item_desc)) AS item_description,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
BenchmarkResults AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        id.item_description,
        id.i_current_price,
        sd.total_quantity,
        sd.total_sales,
        CASE 
            WHEN sd.total_sales > 1000 THEN 'High'
            WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sd.ws_item_sk)
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_id
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    item_description,
    i_current_price,
    total_quantity,
    total_sales,
    sales_category
FROM 
    BenchmarkResults
WHERE 
    item_description LIKE '%s%' 
ORDER BY 
    total_sales DESC, full_name ASC;
