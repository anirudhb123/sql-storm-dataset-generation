
WITH AddressAgg AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(CASE WHEN ca_city LIKE '%ville%' THEN 1 ELSE 0 END) AS city_ending_with_ville,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        COUNT(c.customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
DateStats AS (
    SELECT 
        d_year, 
        COUNT(d_date_sk) AS total_days, 
        SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holidays
    FROM 
        date_dim
    GROUP BY 
        d_year
),
FinalReport AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.city_ending_with_ville,
        a.avg_gmt_offset,
        d.cd_gender,
        d.customer_count,
        d.avg_purchase_estimate,
        d.max_dependents,
        dat.d_year,
        dat.total_days,
        dat.holidays
    FROM 
        AddressAgg AS a
    JOIN 
        DemographicAnalysis AS d ON 1 = 1
    JOIN 
        DateStats AS dat ON 1 = 1
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    ca_state, cd_gender, d_year;
