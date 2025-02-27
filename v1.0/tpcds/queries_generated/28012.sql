
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender IN ('M', 'F') AND 
        cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    s.total_sales,
    s.order_count
FROM 
    customer c
JOIN 
    AddressDetails a ON c.c_current_addr_sk = a.ca_address_id
JOIN 
    Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.ca_state = 'CA' AND 
    (d.cd_marital_status = 'M' OR d.cd_marital_status = 'S')
ORDER BY 
    s.total_sales DESC
LIMIT 50;
