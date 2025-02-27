
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS streets
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count,
        STRING_AGG(cd_education_status, ', ') AS education_levels
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        STRING_AGG(DISTINCT i_item_desc, ', ') AS sold_items
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.streets,
    d.cd_gender,
    d.demo_count,
    d.education_levels,
    s.d_year,
    s.total_sales,
    s.sold_items
FROM 
    AddressSummary a
JOIN 
    DemographicsSummary d ON a.address_count > 10
JOIN 
    SalesSummary s ON s.total_sales > 1000000
ORDER BY 
    a.ca_state, d.cd_gender, s.d_year DESC;
