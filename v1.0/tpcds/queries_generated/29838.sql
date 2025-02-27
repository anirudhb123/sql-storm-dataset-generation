
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS FullName,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS TotalProfit,
        COUNT(ws_order_number) AS TotalOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.FullName,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ai.FullAddress,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country,
    COALESCE(si.TotalProfit, 0) AS TotalProfit,
    COALESCE(si.TotalOrders, 0) AS TotalOrders
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
LEFT JOIN 
    SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
WHERE 
    ci.cd_purchase_estimate > 1000
ORDER BY 
    TotalProfit DESC, 
    FullName ASC;
