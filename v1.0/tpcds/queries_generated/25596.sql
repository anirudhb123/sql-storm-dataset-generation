
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                   THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesSummary AS (
    SELECT 
        c.customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High Value'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.customer_sk
ORDER BY 
    total_sales DESC, ci.full_name;
