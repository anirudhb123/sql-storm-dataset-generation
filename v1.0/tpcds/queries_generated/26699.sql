
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        STRING_AGG(ca_city, ', ') AS city_list, 
        ARRAY_AGG(DISTINCT ca_street_name) AS street_names,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip
    FROM 
        customer_address 
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS demographic_count, 
        AVG(cd_purchase_estimate) AS average_purchase, 
        STRING_AGG(cd_marital_status, ', ') AS marital_status_list
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ss_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ss_ticket_number) AS total_orders,
        STRING_AGG(DISTINCT s_store_name) AS stores_involved
    FROM 
        store_sales 
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    JOIN 
        store ON ss_store_sk = s_store_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.address_count,
    a.city_list,
    a.street_names,
    d.cd_gender,
    d.demographic_count,
    d.average_purchase,
    d.marital_status_list,
    s.d_year,
    s.total_sales,
    s.total_orders,
    s.stores_involved
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON d.demographic_count > 0
JOIN 
    SalesStats s ON s.total_sales > 0
ORDER BY 
    a.address_count DESC, 
    s.total_sales DESC;
