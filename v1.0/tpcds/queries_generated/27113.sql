
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.gender,
        cd.marital_status,
        cd.education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        d.customer_name,
        d.gender,
        d.marital_status,
        d.education_status,
        ad.full_address,
        ad.city_state_zip,
        ad.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        Demographics d
    LEFT JOIN 
        AddressDetails ad ON d.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesDetails sd ON d.c_customer_sk = sd.customer_sk
)
SELECT 
    cd.customer_name,
    cd.gender,
    cd.marital_status,
    cd.education_status,
    cd.full_address,
    cd.city_state_zip,
    cd.ca_country,
    cd.total_sales,
    cd.order_count
FROM 
    CombinedData cd
WHERE 
    cd.total_sales > 1000
ORDER BY 
    cd.total_sales DESC;
