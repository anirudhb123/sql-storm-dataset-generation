
WITH AddressInfo AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS FullCustomerName,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        c_customer_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        (ws_quantity * ws_sales_price) AS TotalSales
    FROM 
        web_sales
),
ItemInfo AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        i_category
    FROM 
        item
),
CombinedInfo AS (
    SELECT 
        ci.FullCustomerName,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.FullAddress,
        si.ws_order_number,
        ii.i_product_name,
        ii.i_brand,
        ii.i_category,
        si.ws_quantity,
        si.TotalSales,
        ci.c_customer_sk
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ai.ca_city = 'San Francisco'
    JOIN 
        SalesInfo si ON si.ws_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
    JOIN 
        ItemInfo ii ON ii.i_item_sk = si.ws_item_sk
)
SELECT 
    FullCustomerName,
    cd_gender,
    cd_marital_status,
    FullAddress,
    COUNT(DISTINCT ws_order_number) AS OrderCount,
    SUM(ws_quantity) AS TotalItemsPurchased,
    SUM(TotalSales) AS TotalSpent
FROM 
    CombinedInfo
GROUP BY 
    FullCustomerName, cd_gender, cd_marital_status, FullAddress
ORDER BY 
    TotalSpent DESC
LIMIT 10;
