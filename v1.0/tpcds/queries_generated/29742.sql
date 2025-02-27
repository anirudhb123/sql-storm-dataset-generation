
WITH AddressInfo AS (
    SELECT 
        DISTINCT ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS FullAddress,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city LIKE '%ville%'
        AND ca.ca_state IN ('CA', 'TX', 'NY')
),
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status, ' - ', cd.cd_education_status) AS DemographicDetails
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_credit_rating = 'Good'
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS TotalSales,
        SUM(ws.ws_ext_discount_amt) AS TotalDiscounts
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450005
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    ai.FullAddress,
    ai.ca_city,
    ai.ca_state,
    di.DemographicDetails,
    si.TotalSales,
    si.TotalDiscounts
FROM 
    AddressInfo ai
JOIN 
    customer c ON ai.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemographicInfo di ON c.c_current_cdemo_sk = di.cd_demo_sk
LEFT JOIN 
    SalesInfo si ON c.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ai.FullAddress IS NOT NULL
ORDER BY 
    si.TotalSales DESC
LIMIT 10;
