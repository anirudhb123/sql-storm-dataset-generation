
WITH AddressStatistics AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS unique_street_names,
        LISTAGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_type), ', ') WITHIN GROUP (ORDER BY CONCAT(ca_street_number, ' ', ca_street_type)) AS unique_address_formats
    FROM customer_address
    GROUP BY ca_city
),
DemographicStatistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        LISTAGG(DISTINCT cd_marital_status, ', ') WITHIN GROUP (ORDER BY cd_marital_status) AS marital_statuses,
        LISTAGG(DISTINCT cd_education_status, ', ') WITHIN GROUP (ORDER BY cd_education_status) AS education_statuses
    FROM customer_demographics
    GROUP BY cd_gender
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        LISTAGG(DISTINCT CAST(ws_ship_mode_sk AS VARCHAR), ', ') WITHIN GROUP (ORDER BY CAST(ws_ship_mode_sk AS VARCHAR)) AS ship_modes
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
)
SELECT 
    a.ca_city,
    a.address_count,
    a.unique_street_names,
    a.unique_address_formats,
    d.cd_gender,
    d.demographic_count,
    d.marital_statuses,
    d.education_statuses,
    s.d_year,
    s.total_sales,
    s.total_orders,
    s.ship_modes
FROM AddressStatistics a
JOIN DemographicStatistics d ON a.address_count > 100
JOIN SalesSummary s ON s.total_sales > 10000
ORDER BY s.d_year DESC, a.ca_city;
