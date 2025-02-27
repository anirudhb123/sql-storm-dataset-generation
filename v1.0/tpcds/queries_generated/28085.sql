
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_city, ', ') AS city_list,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS street_info
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DateCounts AS (
    SELECT 
        d_year,
        COUNT(*) AS total_orders,
        AVG(DATEDIFF(day, d_date, CURRENT_DATE)) AS avg_days_since_order
    FROM 
        date_dim
    JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    GROUP BY 
        d_year
)
SELECT 
    AC.ca_state,
    AC.address_count,
    AC.city_list,
    AC.street_info,
    DS.cd_gender,
    DS.demographic_count,
    DS.avg_purchase_estimate,
    DS.max_dependents,
    DC.d_year,
    DC.total_orders,
    DC.avg_days_since_order
FROM 
    AddressCounts AC
JOIN 
    DemographicStats DS ON AC.address_count > 100
JOIN 
    DateCounts DC ON DC.total_orders > 50
ORDER BY 
    AC.address_count DESC, 
    DS.demographic_count DESC, 
    DC.d_year;
