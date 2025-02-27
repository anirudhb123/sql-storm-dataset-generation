
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca.ca_suite_number), '')) AS FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS FullName,
        c.c_email_address,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(ws.ws_order_number) AS NumberOfPurchases
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_customer_sk
),
FinalReport AS (
    SELECT 
        cd.FullName,
        cd.c_email_address,
        cd.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.FullAddress,
        sd.TotalSales,
        sd.NumberOfPurchases
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_customer_sk
)
SELECT 
    FullName,
    c_email_address,
    c_birth_country,
    cd_gender,
    cd_marital_status,
    FullAddress,
    COALESCE(TotalSales, 0) AS TotalSales,
    COALESCE(NumberOfPurchases, 0) AS NumberOfPurchases
FROM 
    FinalReport
WHERE 
    (cd_gender = 'F' AND TotalSales > 1000) OR 
    (cd_gender = 'M' AND NumberOfPurchases > 10)
ORDER BY 
    TotalSales DESC, NumberOfPurchases DESC
LIMIT 100;
