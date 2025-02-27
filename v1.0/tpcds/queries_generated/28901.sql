
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city LIKE '%town%'
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ds.total_sales,
    ds.order_count,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM 
    CustomerInfo ci
JOIN 
    SalesStats ds ON ci.c_customer_id = ds.ws_bill_customer_sk
JOIN 
    AddressDetails ad ON ci.c_customer_id = ad.full_address
WHERE 
    ds.total_sales > 1000
ORDER BY 
    ds.total_sales DESC;
