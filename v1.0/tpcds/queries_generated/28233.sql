
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
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
        cd_education_status,
        ca_address_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.city_state_zip,
        ad.ca_country,
        sd.order_count,
        sd.total_sales
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.ca_address_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    a.*,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Value'
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    AggregatedData a
WHERE 
    a.cd_gender = 'M' 
    AND a.cd_marital_status = 'S'
ORDER BY 
    a.total_sales DESC;
