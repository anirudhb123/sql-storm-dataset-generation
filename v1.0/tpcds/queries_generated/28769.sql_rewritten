WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(*) AS total_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities_list,
        AVG(length(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
final_benchmark AS (
    SELECT 
        a.ca_state,
        a.unique_addresses,
        a.total_addresses,
        a.cities_list,
        a.avg_street_name_length,
        d.cd_gender,
        d.total_customers,
        d.total_dependents,
        d.avg_purchase_estimate,
        s.total_sales,
        s.total_orders
    FROM 
        address_summary a
    JOIN 
        demographics_summary d ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = 1)  
    JOIN 
        sales_summary s ON s.d_year = 2001  
)
SELECT 
    ca_state,
    unique_addresses,
    total_addresses,
    cities_list,
    avg_street_name_length,
    cd_gender,
    total_customers,
    total_dependents,
    avg_purchase_estimate,
    total_sales,
    total_orders
FROM 
    final_benchmark
ORDER BY 
    total_sales DESC, total_addresses DESC;