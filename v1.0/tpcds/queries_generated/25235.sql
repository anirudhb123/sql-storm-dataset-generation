
WITH Address_Comparison AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        LENGTH(ca_zip) AS zip_length
    FROM 
        customer_address
), Customer_Aggregates AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT c.c_first_name || ' ' || c.c_last_name) AS unique_customers,
        SUM(cd_dep_count) AS total_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        STRING_AGG(DISTINCT CONCAT(cd_gender, ': ', cd_marital_status), '; ') AS gender_marital_summary
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
), Date_Analysis AS (
    SELECT 
        d.d_year,
        COUNT(d.d_date_sk) AS total_days,
        COUNT(DISTINCT d.d_week_seq) AS total_weeks,
        COUNT(DISTINCT d.d_month_seq) AS total_months,
        STRING_AGG(DISTINCT d.d_day_name, ', ') AS unique_days
    FROM 
        date_dim d
    GROUP BY 
        d.d_year
)
SELECT 
    ac.full_address,
    ca.unique_customers,
    ca.total_dependents,
    ca.max_purchase_estimate,
    da.total_days,
    da.total_weeks,
    da.total_months,
    da.unique_days
FROM 
    Address_Comparison ac
JOIN 
    Customer_Aggregates ca ON ca.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer) 
JOIN 
    Date_Analysis da ON da.d_year = (SELECT MAX(d_year) FROM date_dim)
WHERE 
    ac.street_name_length > 5
ORDER BY 
    ac.full_address;
