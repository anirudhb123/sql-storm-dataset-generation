
WITH address_stats AS (
    SELECT
        ca_state,
        COUNT(*) AS address_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM customer_address
    GROUP BY ca_state
),
customer_stats AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
sales_summary AS (
    SELECT
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
),
final_benchmark AS (
    SELECT
        a.ca_state,
        a.address_count,
        a.avg_gmt_offset,
        a.cities,
        c.cd_gender,
        c.customer_count,
        c.avg_purchase_estimate,
        s.total_quantity,
        s.total_sales,
        s.total_orders
    FROM address_stats a
    JOIN customer_stats c ON a.address_count > 100
    CROSS JOIN sales_summary s
    ORDER BY a.address_count DESC, c.customer_count DESC
)
SELECT
    CONCAT('State: ', ca_state, ', Address Count: ', address_count, ', Avg GMT Offset: ', avg_gmt_offset, ', Cities: ', cities, 
           ' | Gender: ', cd_gender, ', Customer Count: ', customer_count, ', Avg Purchase Estimate: ', avg_purchase_estimate, 
           ' | Total Quantity Sold: ', total_quantity, ', Total Sales: ', total_sales, ', Total Orders: ', total_orders) AS benchmark_report
FROM final_benchmark
LIMIT 50;
