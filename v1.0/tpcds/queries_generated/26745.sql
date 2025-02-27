
WITH AddressData AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ship_date_sk
    FROM 
        web_sales
),
JoinedData AS (
    SELECT 
        addr.ca_address_id,
        addr.full_address,
        cust.full_name,
        cust.cd_gender,
        cust.cd_marital_status,
        sales.ws_order_number,
        sales.ws_quantity,
        sales.ws_sales_price,
        sales.ws_ext_sales_price,
        date_dim.d_date
    FROM 
        AddressData addr
    JOIN 
        CustomerData cust ON addr.ca_address_id = cust.c_customer_id
    JOIN 
        SalesData sales ON sales.ws_bill_customer_sk = cust.c_customer_sk
    JOIN 
        date_dim ON sales.ws_sold_date_sk = date_dim.d_date_sk
)
SELECT 
    full_address,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_ext_sales_price) AS total_sales,
    cd_gender,
    cd_marital_status
FROM 
    JoinedData
GROUP BY 
    full_address, cd_gender, cd_marital_status
ORDER BY 
    total_sales DESC
LIMIT 100;
