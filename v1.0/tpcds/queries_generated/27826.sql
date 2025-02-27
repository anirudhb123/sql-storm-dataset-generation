
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
DetailedSales AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        s.total_sales,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip
    FROM 
        CustomerDetails c
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    total_sales,
    full_address,
    ca_city,
    ca_state,
    ca_zip
FROM 
    DetailedSales
WHERE 
    total_sales IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 100;
