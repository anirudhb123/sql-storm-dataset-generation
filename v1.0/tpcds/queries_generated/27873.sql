
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_demo_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cd.full_name,
    ad.full_address,
    sd.total_quantity,
    sd.total_sales,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_item_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    sd.total_sales DESC
LIMIT 50;
