
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_dep_count) AS avg_dependencies,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        s.s_store_name,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
)
SELECT 
    ac.ca_city,
    ac.unique_addresses,
    ac.unique_streets,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_dependencies,
    cd.total_purchase_estimate,
    sd.s_store_name,
    sd.total_sales,
    sd.total_quantity
FROM 
    AddressCounts ac
JOIN 
    CustomerDemographics cd ON ac.unique_addresses > 10
JOIN 
    SalesData sd ON sd.total_sales > 100000
ORDER BY 
    ac.ca_city, cd.cd_gender, sd.total_sales DESC;
