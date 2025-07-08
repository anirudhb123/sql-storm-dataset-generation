
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(BOTH ' ' FROM REPLACE(ca_city, ',', '')) AS cleaned_city,
        ca_state,
        COUNT(DISTINCT ca_zip) AS zip_count
    FROM 
        customer_address
    GROUP BY 
        ca_address_sk, ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.full_address,
    ad.cleaned_city,
    ad.ca_state,
    ad.zip_count,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerDetails cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressDetails ad ON ca.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ad.cleaned_city LIKE '%York%'
ORDER BY 
    total_sales DESC
LIMIT 100;
