
WITH AddressAggregation AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name || ' ' || ca_street_number, '; ') AS street_info
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
DemographicsAggregation AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_demographics
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesAggregation AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    aa.ca_city,
    aa.ca_state,
    aa.total_addresses,
    aa.street_info,
    da.cd_gender,
    da.cd_marital_status,
    da.total_demographics,
    sa.d_year,
    sa.total_sales
FROM 
    AddressAggregation aa
JOIN 
    DemographicsAggregation da ON aa.ca_state = 'CA' 
JOIN 
    SalesAggregation sa ON sa.d_year BETWEEN 2018 AND 2022
WHERE 
    aa.total_addresses > 100
ORDER BY 
    sa.total_sales DESC, aa.total_addresses DESC;
