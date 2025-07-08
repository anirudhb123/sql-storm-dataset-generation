
WITH AddressCounts AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_street_name, '; ') WITHIN GROUP (ORDER BY ca_street_name) AS unique_streets,
        LISTAGG(DISTINCT ca_suite_number, '; ') WITHIN GROUP (ORDER BY ca_suite_number) AS suite_numbers
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        LISTAGG(cd_education_status, '; ') WITHIN GROUP (ORDER BY cd_education_status) AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStatistics AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sales_per_order,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    ac.address_count,
    ac.unique_streets,
    ac.suite_numbers,
    cd.cd_gender,
    cd.demographic_count,
    cd.education_levels,
    ss.d_year,
    ss.total_sales,
    ss.avg_sales_per_order,
    ss.total_orders
FROM 
    AddressCounts ac
FULL OUTER JOIN 
    CustomerDemographics cd ON ac.ca_city = 'New York' AND cd.cd_gender = 'F'
FULL OUTER JOIN 
    SalesStatistics ss ON ss.d_year = 2023
ORDER BY 
    ac.ca_city, cd.cd_gender, ss.d_year;
