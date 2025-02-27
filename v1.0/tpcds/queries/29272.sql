WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MIN(ca_zip) AS min_zip,
        MAX(ca_zip) AS max_zip,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_credit_rating, ', ') AS credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    A.ca_state,
    A.address_count,
    A.avg_street_name_length,
    A.min_zip,
    A.max_zip,
    A.unique_cities,
    C.cd_gender,
    C.customer_count,
    C.avg_purchase_estimate,
    C.credit_ratings,
    S.d_year,
    S.total_sales,
    S.total_net_paid,
    S.total_orders
FROM 
    AddressStats A
CROSS JOIN 
    CustomerStats C
JOIN 
    SalesData S ON S.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
ORDER BY 
    A.address_count DESC, C.customer_count DESC;