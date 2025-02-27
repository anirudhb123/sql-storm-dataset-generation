
WITH AddressStatistics AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_street_names,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS unique_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS demographics_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesPerformance AS (
    SELECT 
        d_year,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    A.ca_city,
    A.ca_state,
    A.address_count,
    A.unique_street_names,
    A.unique_street_types,
    C.cd_gender,
    C.cd_marital_status,
    C.demographics_count,
    S.d_year,
    S.total_sales,
    S.total_quantity
FROM 
    AddressStatistics A
LEFT JOIN 
    CustomerDemographics C ON A.ca_city = 'San Francisco' AND A.ca_state = 'CA' 
LEFT JOIN 
    SalesPerformance S ON S.d_year = 2023
ORDER BY 
    A.address_count DESC, S.total_sales DESC;
