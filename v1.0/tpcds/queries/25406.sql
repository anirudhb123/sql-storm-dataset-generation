
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
FinalReport AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.cities,
        a.street_types,
        d.cd_gender,
        d.avg_purchase_estimate,
        d.demographic_count,
        s.d_year,
        s.total_net_profit,
        s.total_quantity_sold
    FROM 
        AddressStats a
    LEFT JOIN 
        DemographicsStats d ON a.ca_state IN (SELECT DISTINCT ca_state FROM customer_address)
    LEFT JOIN 
        SalesStats s ON s.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
)
SELECT 
    * 
FROM 
    FinalReport
ORDER BY 
    ca_state, cd_gender, d_year;
