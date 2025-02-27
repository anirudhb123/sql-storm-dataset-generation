
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd.ed_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        sd.total_sales,
        sd.total_orders
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    full_address,
    ca_city, 
    ca_state,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    CombinedData
WHERE 
    ca_state = 'CA' 
ORDER BY 
    total_sales DESC
LIMIT 100;
