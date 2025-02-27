
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS FullAddress,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS FullName,
        c_email_address,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS TotalNetProfit,
        COUNT(ws_order_number) AS TotalOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.FullName,
    ci.email_address,
    sa.TotalNetProfit,
    sa.TotalOrders,
    ai.FullAddress,
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.ca_country
FROM 
    CustomerInfo ci
JOIN 
    SalesData sa ON ci.c_customer_sk = sa.ws_bill_customer_sk
JOIN 
    AddressInfo ai ON ci.c_current_addr_sk = ai.ca_address_sk
WHERE 
    ci.gender = 'F' 
    AND ci.purchase_estimate > 1000
ORDER BY 
    sa.TotalNetProfit DESC 
LIMIT 50;
