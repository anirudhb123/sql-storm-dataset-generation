
WITH AddressStats AS (
    SELECT 
        ca_city, 
        ca_state,
        COUNT(*) AS total_addresses,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_credit_rating, ', ') AS unique_credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        STRING_AGG(DISTINCT ws_ship_mode_sk::text, ', ') AS unique_shipping_modes
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)

SELECT 
    AS.address_stats,
    CS.customer_stats,
    SS.sales_stats
FROM 
    (SELECT * FROM AddressStats) AS address_stats
JOIN 
    (SELECT * FROM CustomerStats) AS customer_stats ON address_stats.ca_state = customer_stats.cd_gender
JOIN 
    (SELECT * FROM SalesStats) AS sales_stats ON sales_stats.d_year = EXTRACT(YEAR FROM current_date)
ORDER BY 
    total_sales DESC;
