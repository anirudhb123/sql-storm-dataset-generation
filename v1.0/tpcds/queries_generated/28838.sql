
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
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
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders 
    FROM 
        web_sales ws 
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders
FROM 
    CustomerDetails cd 
JOIN 
    AddressDetails ad ON ad.ca_address_sk = cd.c_customer_sk -- assuming a fictitious relation for ON clause
LEFT JOIN 
    SalesData sd ON sd.bill_customer_sk = cd.c_customer_sk 
ORDER BY 
    sd.total_sales DESC 
LIMIT 100;
