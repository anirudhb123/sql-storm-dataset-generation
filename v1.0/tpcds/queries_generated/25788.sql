
WITH Address_City AS (
    SELECT DISTINCT ca_city, 
           COUNT(*) OVER (PARTITION BY ca_city) AS city_count, 
           STRING_AGG(ca_street_name, ', ') WITHIN GROUP (ORDER BY ca_street_name) AS street_names
    FROM customer_address
    GROUP BY ca_city
),
Demographic_Stats AS (
    SELECT cd_gender, 
           COUNT(*) AS total_customers, 
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           MAX(cd_dep_count) AS max_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),
Date_Range AS (
    SELECT d_year, 
           d_month_seq, 
           SUM(d_dom) AS total_days
    FROM date_dim
    GROUP BY d_year, d_month_seq
),
Sales_Summary AS (
    SELECT 
        t.t_year,
        sm.sm_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY t.t_year, sm.sm_type
)
SELECT 
    a.ca_city, 
    a.city_count, 
    a.street_names, 
    d.cd_gender, 
    d.total_customers, 
    d.avg_purchase_estimate, 
    d.max_dependents, 
    dr.d_year, 
    dr.d_month_seq, 
    dr.total_days, 
    ss.t_year, 
    ss.sm_type, 
    ss.total_sales, 
    ss.unique_orders
FROM Address_City a
JOIN Demographic_Stats d ON a.city_count > d.total_customers / 10
JOIN Date_Range dr ON dr.d_year = 2023
JOIN Sales_Summary ss ON ss.t_year = dr.d_year
WHERE a.city_count > 5 AND d.cd_gender = 'F'
ORDER BY a.ca_city, d.cd_gender, ss.total_sales DESC;
