
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demo_summary AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd_education_status, ', ') AS education_statuses
    FROM
        customer_demographics
    GROUP BY 
        cd_gender
),
daily_sales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
),
final_benchmark AS (
    SELECT 
        as.ca_state,
        as.unique_addresses,
        as.avg_street_name_length,
        as.max_street_name_length,
        as.min_street_name_length,
        as.cities_list,
        ds.cd_gender,
        ds.demographic_count,
        ds.avg_purchase_estimate,
        ds.education_statuses,
        ds.demographic_count * fs.total_sales AS sales_per_demographic
    FROM 
        address_summary as
    CROSS JOIN 
        demo_summary ds
    JOIN 
        (SELECT 
            AVG(total_sales) AS total_avg_sales
         FROM 
            daily_sales) fs ON 1=1
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 5000 THEN 'High Sales'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    final_benchmark
ORDER BY 
    unique_addresses DESC, total_orders DESC
LIMIT 100;
