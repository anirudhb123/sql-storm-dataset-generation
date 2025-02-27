
WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        LENGTH(ca_street_name) AS street_name_length, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(CAST(ca_zip AS VARCHAR)) AS zip_code
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        ca.city AS customer_city,
        ca.state AS customer_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        CONCAT(i_brand, ' - ', i_category) AS brand_category
    FROM 
        item
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    ad.full_address,
    id.i_product_name,
    id.brand_category,
    sd.total_sales,
    sd.order_count
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.customer_city = ad.ca_city AND ci.customer_state = ad.ca_state
JOIN 
    ItemDetails id ON ci.c_customer_sk = id.i_item_sk
JOIN 
    SalesData sd ON id.i_item_sk = sd.ws_item_sk
WHERE 
    ad.street_name_length > 5
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
