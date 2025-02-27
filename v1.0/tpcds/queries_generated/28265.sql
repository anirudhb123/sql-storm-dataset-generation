
WITH AddressDetails AS (
    SELECT 
        ca.cust_address,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               COALESCE(CONCAT(' ', ca.ca_suite_number), '')) AS FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY', 'TX')
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        Row_Number() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) as Rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(ws.ws_order_number) AS OrderCount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ad.FullAddress,
    ss.TotalSales,
    ss.OrderCount
FROM 
    CustomerInfo ci
JOIN 
    AddressDetails ad ON ci.c_customer_sk = ad.cust_address
JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ci.Rnk <= 5 AND ss.TotalSales > 10000
ORDER BY 
    ci.c_last_name, ci.c_first_name;
