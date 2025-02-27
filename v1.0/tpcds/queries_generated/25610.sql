
SELECT 
    CA.ca_city AS City,
    CA.ca_state AS State,
    CD.cd_gender AS Gender,
    CD.cd_marital_status AS MaritalStatus,
    COUNT(DISTINCT C.c_customer_sk) AS CustomerCount,
    SUM(CD.cd_purchase_estimate) AS TotalPurchaseEstimate,
    AVG(CD.cd_dep_count) AS AverageDependentCount,
    STRING_AGG(DISTINCT CONCAT_WS(' ', C.c_first_name, C.c_last_name), ', ') AS Customers,
    STRING_AGG(DISTINCT CONCAT_WS(', ', CA.ca_street_number, CA.ca_street_name, CA.ca_street_type), '; ') AS Addresses
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
WHERE 
    CA.ca_state IN ('NY', 'CA')
GROUP BY 
    CA.ca_city, CA.ca_state, CD.cd_gender, CD.cd_marital_status
ORDER BY 
    TotalPurchaseEstimate DESC
LIMIT 10;
