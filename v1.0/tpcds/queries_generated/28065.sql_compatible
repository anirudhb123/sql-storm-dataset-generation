
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low Value'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        CASE 
            WHEN ws.ws_bill_customer_sk IS NOT NULL THEN 'Web'
            WHEN cs.cs_bill_customer_sk IS NOT NULL THEN 'Catalog'
            ELSE 'Store'
        END AS sale_channel,
        sd.c_customer_sk, 
        SUM(COALESCE(ws.ws_net_paid, cs.cs_net_paid, ss.ss_net_paid, 0)) AS total_sales
    FROM 
        web_sales ws 
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_bill_customer_sk = cs.cs_bill_customer_sk 
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk OR cs.cs_bill_customer_sk = ss.ss_customer_sk
    JOIN 
        customer sd ON ws.ws_bill_customer_sk = sd.c_customer_sk OR cs.cs_bill_customer_sk = sd.c_customer_sk OR ss.ss_customer_sk = sd.c_customer_sk
    GROUP BY 
        sale_channel, sd.c_customer_sk
)
SELECT 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ai.full_address, 
    sd.sale_channel, 
    sd.total_sales
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
JOIN 
    SalesData sd ON ci.c_customer_id = sd.c_customer_sk
WHERE 
    ci.customer_value_category = 'High Value'
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
