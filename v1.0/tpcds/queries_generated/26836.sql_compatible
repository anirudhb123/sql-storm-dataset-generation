
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS FullName,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.FullAddress,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS OrderCount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cs.FullName,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.cd_purchase_estimate,
    ad.FullAddress,
    ad.ca_city,
    ad.ca_state,
    COALESCE(sd.TotalSales, 0) AS TotalSales,
    COALESCE(sd.OrderCount, 0) AS OrderCount
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesData sd ON cs.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    LENGTH(cs.FullName) > 0 
    AND cs.cd_gender = 'M' 
    AND cs.cd_marital_status = 'S'
ORDER BY 
    TotalSales DESC,
    cs.FullName;
