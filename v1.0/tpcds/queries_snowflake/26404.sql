
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        ca_zip,
        COUNT(DISTINCT ca_address_id) AS AddressCount,
        LISTAGG(DISTINCT ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS UniqueStreetNames
    FROM 
        customer_address 
    WHERE 
        ca_country = 'USA'
    GROUP BY 
        ca_city, ca_state, ca_zip
),
DemographicInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesInfo AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS TotalSales
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.ca_zip,
    ai.AddressCount,
    ai.UniqueStreetNames,
    di.cd_gender,
    di.cd_marital_status,
    di.CustomerCount,
    si.TotalSales
FROM 
    AddressInfo ai
JOIN 
    DemographicInfo di ON di.CustomerCount > 0
LEFT JOIN 
    SalesInfo si ON si.ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = ai.ca_city AND ca_state = ai.ca_state AND ca_zip = ai.ca_zip)
ORDER BY 
    ai.ca_state, ai.ca_city;
