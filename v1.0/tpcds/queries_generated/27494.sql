
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS street_names,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        date_dim AS d
    LEFT JOIN 
        web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales AS cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales AS ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.address_count,
    ad.street_names,
    ad.street_types,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_purchase_estimate,
    ss.d_year,
    ss.total_web_sales,
    ss.total_catalog_sales,
    ss.total_store_sales
FROM 
    AddressDetails ad
JOIN 
    CustomerDemographics cd ON ad.ca_city = 'San Francisco' AND cd.cd_gender = 'F'
JOIN 
    SalesSummary ss ON ss.d_year BETWEEN 2020 AND 2023
ORDER BY 
    ad.ca_state, cd.cd_gender, ss.d_year;
