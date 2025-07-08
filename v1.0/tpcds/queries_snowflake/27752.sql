
WITH AddressGroup AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS AddressCount,
        LISTAGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') WITHIN GROUP (ORDER BY ca_street_number) AS FullAddress
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
), 
CustomerAnalysis AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS TotalCustomers, 
        AVG(cd_purchase_estimate) AS AveragePurchaseEstimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    ag.ca_city,
    ag.ca_state,
    ag.AddressCount,
    ag.FullAddress,
    ca.cd_gender,
    ca.TotalCustomers,
    ca.AveragePurchaseEstimate
FROM 
    AddressGroup ag
JOIN 
    CustomerAnalysis ca ON ag.ca_state = 'CA'  
ORDER BY 
    ag.AddressCount DESC, 
    ca.TotalCustomers DESC;
