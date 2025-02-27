WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(ca_street_name, ',') AS street_names,
        STRING_AGG(DISTINCT ca_city, ',') AS distinct_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsEnhancement AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
DateInfo AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(*) AS sale_count
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
FullBenchmark AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.street_names,
        a.distinct_cities,
        d.d_year,
        d.d_month_seq,
        d.sale_count,
        de.cd_gender,
        de.cd_marital_status,
        de.avg_purchase_estimate
    FROM 
        AddressStats AS a
    CROSS JOIN 
        DateInfo AS d
    INNER JOIN 
        DemographicsEnhancement AS de ON 1=1  
)
SELECT 
    ca_state,
    address_count,
    street_names,
    distinct_cities,
    d_year,
    d_month_seq,
    sale_count,
    cd_gender,
    cd_marital_status,
    avg_purchase_estimate
FROM 
    FullBenchmark
ORDER BY 
    ca_state, d_year, d_month_seq;