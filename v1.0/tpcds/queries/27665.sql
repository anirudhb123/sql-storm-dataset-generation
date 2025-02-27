
WITH AddressData AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        c_customer_sk,
        c_current_addr_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
DetailedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_sales_amount,
        CONCAT(a.full_address, ', ', a.ca_city, ', ', a.ca_state, ' ', a.ca_zip, ', ', a.ca_country) AS complete_address,
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    JOIN 
        CustomerData c ON c.c_customer_sk = (SELECT DISTINCT ws_ship_customer_sk FROM web_sales WHERE ws_item_sk = sd.ws_item_sk LIMIT 1) 
    JOIN 
        AddressData a ON a.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    ds.ws_item_sk,
    ds.total_sales,
    ds.total_sales_amount,
    ds.complete_address,
    ds.full_name,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status
FROM 
    DetailedSales ds
WHERE 
    ds.total_sales > 10
ORDER BY 
    ds.total_sales_amount DESC;
