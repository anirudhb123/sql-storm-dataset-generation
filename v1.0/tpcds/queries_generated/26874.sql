
WITH AddressDetails AS (
    SELECT
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_address_list
    FROM
        customer_address
    GROUP BY
        ca_state,
        ca_city
),
DemographicsDetails AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        STRING_AGG(CONCAT(cd_marital_status, ' - ', cd_education_status), '; ') AS demographic_categories
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
SalesSummary AS (
    SELECT
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
)
SELECT
    ad.ca_state,
    ad.ca_city,
    ad.address_count,
    ad.full_address_list,
    dd.cd_gender,
    dd.demographic_count,
    dd.demographic_categories,
    ss.d_year,
    ss.total_sales,
    ss.total_orders
FROM
    AddressDetails ad
JOIN DemographicsDetails dd ON TRUE
JOIN SalesSummary ss ON TRUE
ORDER BY
    ad.ca_state, ad.ca_city, dd.cd_gender, ss.d_year;
