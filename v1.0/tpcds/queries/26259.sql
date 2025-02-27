
WITH Address_Analysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_city)) AS avg_city_length,
        SUM(CASE WHEN ca_street_type LIKE '%Avenue%' THEN 1 ELSE 0 END) AS is_avenue_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM customer_address
    GROUP BY ca_state
),
Customer_Analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM customer_demographics
    GROUP BY cd_gender
),
Sales_Impact AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
),
Final_Results AS (
    SELECT 
        aa.ca_state,
        aa.unique_addresses,
        aa.avg_street_name_length,
        ca.customer_count,
        ca.avg_dependents,
        si.total_sales,
        si.orders_count,
        si.total_quantity,
        aa.is_avenue_count,
        aa.cities
    FROM Address_Analysis aa
    JOIN Customer_Analysis ca ON 1=1
    JOIN Sales_Impact si ON 1=1
)
SELECT 
    fa.ca_state,
    fa.unique_addresses,
    fa.avg_street_name_length,
    fa.customer_count,
    fa.avg_dependents,
    fa.total_sales,
    fa.orders_count,
    fa.total_quantity,
    fa.is_avenue_count,
    fa.cities
FROM Final_Results fa
ORDER BY fa.ca_state;
