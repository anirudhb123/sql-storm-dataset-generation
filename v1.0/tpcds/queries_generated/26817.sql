
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            ELSE 'Female' 
        END AS gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ws_bill_customer_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_bill_customer_sk
)

SELECT 
    d.gender,
    d.cd_marital_status,
    d.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    sd.total_quantity,
    sd.total_sales
FROM 
    SalesData sd
JOIN 
    Demographics d ON sd.ws_bill_customer_sk = d.cd_demo_sk
JOIN 
    AddressDetails ad ON sd.ws_bill_customer_sk = d.cd_demo_sk
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
