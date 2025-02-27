
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedDetails AS (
    SELECT 
        c.full_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        s.total_sales,
        s.order_count,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status
    FROM 
        CustomerDetails c
    LEFT JOIN 
        SalesDetails s ON c.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    full_name,
    full_address,
    total_sales,
    order_count,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    CombinedDetails
ORDER BY 
    total_sales DESC;
