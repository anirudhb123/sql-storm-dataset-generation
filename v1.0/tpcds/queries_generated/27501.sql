
WITH AddressInfo AS (
    SELECT 
        CA.ca_city,
        CA.ca_state,
        COUNT(CA.ca_address_sk) AS AddressCount,
        STRING_AGG(DISTINCT CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type), '; ') AS FullAddress
    FROM 
        customer_address CA
    GROUP BY 
        CA.ca_city, CA.ca_state
),
CustomerInfo AS (
    SELECT 
        C.c_customer_id,
        CONCAT(C.c_first_name, ' ', C.c_last_name) AS FullName,
        D.cd_gender,
        D.cd_marital_status
    FROM 
        customer C
    LEFT JOIN 
        customer_demographics D ON C.c_current_cdemo_sk = D.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        WS.ws_item_sk,
        SUM(WS.ws_quantity) AS TotalQuantity,
        AVG(WS.ws_sales_price) AS AvgSalesPrice,
        SUM(WS.ws_net_profit) AS TotalNetProfit
    FROM 
        web_sales WS
    GROUP BY 
        WS.ws_item_sk
)
SELECT 
    C.FullName,
    C.cd_gender,
    C.cd_marital_status,
    A.ca_city,
    A.ca_state,
    A.AddressCount,
    A.FullAddress,
    S.TotalQuantity,
    S.AvgSalesPrice,
    S.TotalNetProfit
FROM 
    CustomerInfo C
JOIN 
    customer_address A ON C.c_customer_sk = A.ca_address_sk
LEFT JOIN 
    SalesInfo S ON A.ca_address_sk = S.ws_item_sk
WHERE 
    A.ca_state = 'CA' 
AND 
    C.cd_marital_status = 'M'
ORDER BY 
    S.TotalNetProfit DESC
LIMIT 100;
