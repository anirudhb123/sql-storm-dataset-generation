
WITH AddressDetails AS (
    SELECT 
        ca.city AS Address_City,
        ca.state AS Address_State, 
        ca.zip AS Address_Zip,
        COUNT(DISTINCT c.c_customer_sk) AS Customer_Count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.city IS NOT NULL 
        AND ca.state IS NOT NULL
    GROUP BY 
        ca.city, ca.state, ca.zip
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS Total_Customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ad.Address_City, 
    ad.Address_State, 
    ad.Address_Zip,
    ad.Customer_Count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.Total_Customers
FROM 
    AddressDetails ad
JOIN 
    CustomerDemographics cd ON ad.Customer_Count > 0
ORDER BY 
    ad.Address_City, ad.Customer_Count DESC, cd.Total_Customers DESC;
