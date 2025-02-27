
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_city) AS total_cities,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_units_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_cities,
    a.cities,
    d.cd_gender,
    d.total_customers,
    d.avg_purchase_estimate,
    d.marital_statuses,
    s.d_year,
    s.total_sales,
    s.total_units_sold
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON 'CA' = a.ca_state  
JOIN 
    SalesStats s ON s.total_units_sold > 1000  
ORDER BY 
    a.unique_addresses DESC, 
    s.total_sales DESC;
