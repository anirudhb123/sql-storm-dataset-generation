
WITH CustomerFullName AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
DemographicsSummary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.full_name,
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_tax, 0) AS total_tax,
    d.customer_count
FROM 
    CustomerFullName c
JOIN 
    customer_address ca ON c.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressDetails a ON ca.ca_address_sk = a.ca_address_sk
JOIN 
    DemographicsSummary d ON d.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    SalesSummary s ON s.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    d.customer_count > 1
ORDER BY 
    total_sales DESC;
