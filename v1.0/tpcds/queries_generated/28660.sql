
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name, '; ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicCounts AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS demo_count,
        STRING_AGG(DISTINCT cd_gender, ', ') AS genders
    FROM 
        customer_demographics
    GROUP BY 
        cd_marital_status
),
SalesData AS (
    SELECT 
        d_year,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ac.ca_state,
    ac.address_count,
    ac.cities,
    ac.street_names,
    dc.cd_marital_status,
    dc.demo_count,
    dc.genders,
    sd.d_year,
    sd.total_sales,
    sd.unique_customers
FROM 
    AddressCounts ac
JOIN 
    DemographicCounts dc ON ac.address_count > 100
JOIN 
    SalesData sd ON sd.total_sales > 10000
ORDER BY 
    ac.ca_state, dc.cd_marital_status, sd.d_year;
