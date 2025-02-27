
WITH AddressCTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
CustomerCTE AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca.city AS customer_city,
        ca.state AS customer_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressCTE ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cc.full_name,
    cc.cd_gender,
    cc.cd_marital_status,
    cc.cd_education_status,
    a.full_address,
    a.ca_city,
    a.ca_state,
    COALESCE(s.total_orders, 0) AS total_orders,
    COALESCE(s.total_sales, 0.00) AS total_sales
FROM 
    CustomerCTE cc
JOIN 
    AddressCTE a ON cc.customer_city = a.ca_city AND cc.customer_state = a.ca_state
LEFT JOIN 
    SalesCTE s ON cc.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    cc.cd_gender = 'F' AND cc.cd_marital_status = 'M' 
ORDER BY 
    total_sales DESC
LIMIT 50;
