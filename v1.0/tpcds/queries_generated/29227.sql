
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerFullNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(*) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerAddressSales AS (
    SELECT 
        CAF.ca_address_sk,
        CAF.full_address,
        CAF.ca_city,
        CAF.ca_state,
        CAF.ca_zip,
        CAF.ca_country,
        CF.full_name,
        COALESCE(SD.total_sales, 0) AS total_sales,
        COALESCE(SD.order_count, 0) AS order_count
    FROM 
        AddressParts CAF
    LEFT JOIN 
        CustomerFullNames CF ON CF.c_customer_sk = (SELECT c_current_addr_sk FROM customer WHERE c_current_addr_sk = CAF.ca_address_sk)
    LEFT JOIN 
        SalesData SD ON SD.ws_bill_customer_sk = CF.c_customer_sk
)
SELECT 
    ca_city,
    ca_state,
    ca_country,
    AVG(total_sales) AS avg_sales,
    AVG(order_count) AS avg_orders,
    COUNT(DISTINCT full_address) AS unique_addresses
FROM 
    CustomerAddressSales
WHERE 
    total_sales > 0
GROUP BY 
    ca_city, ca_state, ca_country
ORDER BY 
    avg_sales DESC;
