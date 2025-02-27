
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        i_item_desc
    FROM item
),
SalesDetails AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    id.i_product_name,
    id.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ad.ca_state ORDER BY sd.total_sales DESC) AS sales_rank
FROM AddressDetails ad
JOIN CustomerDetails cd ON cd.c_customer_sk IN (
    SELECT 
        DISTINCT ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk IN (SELECT i_item_sk FROM SalesDetails)
)
JOIN SalesDetails sd ON sd.ws_item_sk IN (
    SELECT i_item_sk FROM ItemDetails
)
JOIN ItemDetails id ON sd.ws_item_sk = id.i_item_sk
WHERE ad.ca_state = 'CA'
ORDER BY sd.total_sales DESC;
