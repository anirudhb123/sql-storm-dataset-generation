
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(TRIM(ca_street_name)) AS processed_street_name,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_type)) AS full_address,
        CONCAT(TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)) AS city_state_zip
    FROM customer_address
), gender_income_summary AS (
    SELECT 
        cd_gender,
        ib_lower_bound,
        ib_upper_bound,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    JOIN customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, ib_lower_bound, ib_upper_bound
), daily_sales_summary AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM date_dim
    JOIN web_sales ON d_date_sk = ws_sold_date_sk
    GROUP BY d_year, d_month_seq
)
SELECT 
    pa.processed_street_name,
    pa.full_address,
    pa.city_state_zip,
    gis.cd_gender,
    gis.ib_lower_bound,
    gis.ib_upper_bound,
    gis.customer_count,
    gis.avg_purchase_estimate,
    dss.d_year,
    dss.d_month_seq,
    dss.total_sales,
    dss.order_count
FROM processed_addresses pa
JOIN gender_income_summary gis ON gis.customer_count > 0
JOIN daily_sales_summary dss ON dss.total_sales > 0
WHERE LENGTH(pa.processed_street_name) > 3
ORDER BY pa.processed_street_name, gis.cd_gender, gis.ib_lower_bound;
