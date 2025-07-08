
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') WITHIN GROUP (ORDER BY ca_street_number, ca_street_name, ca_street_type) AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.full_addresses,
    di.cd_gender,
    di.cd_marital_status,
    di.demographic_count,
    ss.total_profit,
    ss.total_quantity
FROM 
    AddressCounts ac
LEFT JOIN 
    DemographicInfo di ON ac.address_count > 10
JOIN 
    SalesSummary ss ON ss.total_quantity > 1000
ORDER BY 
    ac.address_count DESC, di.demographic_count DESC;
