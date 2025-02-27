
WITH address_stats AS (
    SELECT
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(ca_street_name, ', ') AS street_names,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip
    FROM customer_address
    GROUP BY ca_city
),
demographics_stats AS (
    SELECT
        cd_gender,
        COUNT(c_demo_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        STRING_AGG(cd_marital_status, ', ') AS marital_statuses
    FROM customer_demographics
    GROUP BY cd_gender
),
sales_summary AS (
    SELECT
        ws_bill_addr_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_addr_sk
),
final_benchmark AS (
    SELECT
        a.ca_city,
        a.unique_addresses,
        a.street_names,
        d.cd_gender,
        d.total_customers,
        d.avg_dependent_count,
        s.total_quantity,
        s.total_profit
    FROM address_stats a
    JOIN demographics_stats d ON d.total_customers > 10
    LEFT JOIN sales_summary s ON s.ws_bill_addr_sk = a.ca_address_sk
)
SELECT
    ca_city,
    unique_addresses,
    street_names,
    cd_gender,
    total_customers,
    avg_dependent_count,
    total_quantity,
    total_profit
FROM final_benchmark
WHERE total_profit > 1000
ORDER BY ca_city, cd_gender, total_profit DESC;
