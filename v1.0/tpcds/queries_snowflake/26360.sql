
WITH ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        LOWER(i.i_item_desc) AS lowered_desc,
        LENGTH(i.i_item_desc) AS desc_length,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk, ws.ws_sold_date_sk
),
CustomerSales AS (
    SELECT 
        ci.full_name,
        sd.total_quantity,
        sd.total_sales,
        id.lowered_desc,
        id.desc_length,
        id.i_current_price
    FROM 
        CustomerInfo ci
    JOIN 
        store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    JOIN 
        ItemDetails id ON ss.ss_item_sk = id.i_item_sk
    JOIN 
        SalesData sd ON id.i_item_sk = sd.ws_item_sk
)
SELECT 
    full_name,
    lowered_desc,
    desc_length,
    total_quantity,
    total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS sales_category
FROM 
    CustomerSales
WHERE 
    LOWER(lowered_desc) LIKE '%organic%'
ORDER BY 
    total_sales DESC;
