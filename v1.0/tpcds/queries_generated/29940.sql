
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WordCount AS (
    SELECT 
        ca_address_id,
        LENGTH(full_address) - LENGTH(REPLACE(full_address, ' ', '')) + 1 AS word_count
    FROM 
        AddressInfo
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.full_address,
    wc.word_count,
    si.order_count,
    si.total_sales
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ai.ca_address_id = ci.c_customer_id
JOIN 
    WordCount wc ON wc.ca_address_id = ai.ca_address_id
LEFT JOIN 
    SalesInfo si ON si.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    ci.cd_gender = 'F' AND 
    si.order_count > 5 AND 
    wc.word_count > 5
ORDER BY 
    si.total_sales DESC
LIMIT 100;
