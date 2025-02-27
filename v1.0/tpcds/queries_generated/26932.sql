
WITH AddressData AS (
    SELECT 
        ca_address_id, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city, 
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    d.full_name,
    ad.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    Demographics d
LEFT JOIN 
    AddressData ad ON d.c_customer_sk = c.c_customer_sk 
LEFT JOIN 
    SalesData sd ON d.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ad.ca_state = 'CA' 
ORDER BY 
    total_sales DESC 
LIMIT 100;
