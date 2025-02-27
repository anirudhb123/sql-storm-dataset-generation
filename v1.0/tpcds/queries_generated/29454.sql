
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca.ca_suite_number), '')) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesSummary AS (
    SELECT 
        cs.bill_cdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.bill_cdemo_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.bill_cdemo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC;
