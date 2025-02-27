
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        UPPER(ca_street_name) AS upper_street_name,
        LOWER(ca_street_type) AS lower_street_type,
        LENGTH(ca_suite_number) AS suite_length,
        ca_country
    FROM customer_address
    WHERE ca_country LIKE 'United States%'
),
DemographicInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM customer_demographics
    WHERE cd_purchase_estimate > 5000 AND cd_credit_rating IN ('Good', 'Very Good')
),
DateTimeInfo AS (
    SELECT 
        d_date,
        CASE 
            WHEN d_dow IN (6, 0) THEN 'Weekend'
            ELSE 'Weekday'
        END AS week_type,
        d_month_seq,
        d_year
    FROM date_dim
    WHERE d_year = 2023
),
Popularity AS (
    SELECT
        i_item_desc,
        COUNT(ws_item_sk) AS sales_count
    FROM web_sales
    GROUP BY i_item_desc
    HAVING COUNT(ws_item_sk) > 100
),
FinalResult AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        di.cd_purchase_estimate,
        dt.d_date,
        dt.week_type,
        p.i_item_desc,
        p.sales_count
    FROM AddressInfo ai
    JOIN DemographicInfo di ON ai.ca_country = 'United States'
    CROSS JOIN DateTimeInfo dt
    JOIN Popularity p ON dt.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT 
    ca_city, 
    ca_state, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    cd_purchase_estimate, 
    d_date,
    week_type,
    i_item_desc,
    sales_count
FROM FinalResult
ORDER BY ca_city, cd_gender, d_date DESC;
