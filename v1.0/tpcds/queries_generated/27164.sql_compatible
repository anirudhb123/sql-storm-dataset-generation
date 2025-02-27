
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS FullAddress,
        ca_city, 
        ca_state, 
        ca_zip, 
        ca_country
    FROM 
        customer_address 
    WHERE 
        ca_city LIKE '%New%' 
        AND ca_state IN ('CA', 'NY')
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS FullName, 
        cd_gender, 
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate > 5000
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS OrderCount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.FullName, 
        a.FullAddress, 
        a.ca_city, 
        a.ca_state, 
        s.TotalSales, 
        s.OrderCount 
    FROM 
        CustomerDetails c
    JOIN 
        SalesDetails s ON c.c_customer_sk = s.ws_bill_customer_sk
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ca_state, 
    COUNT(*) AS CustomerCount, 
    AVG(TotalSales) AS AvgTotalSales, 
    AVG(OrderCount) AS AvgOrderCount
FROM 
    CombinedData
GROUP BY 
    ca_state
ORDER BY 
    CustomerCount DESC;
