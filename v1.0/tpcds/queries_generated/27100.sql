
WITH address_summary AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_address_sk) AS total_addresses,
        CONCAT(ca_city, ', ', ca_state) AS city_state_combination
    FROM
        customer_address
    GROUP BY
        ca_city,
        ca_state
),
demographics_summary AS (
    SELECT
        cd_gender,
        COUNT(c_demo_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        STRING_AGG(cd_marital_status, ', ') AS marital_status_list
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
sales_summary AS (
    SELECT
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk
),
final_report AS (
    SELECT
        a.ca_city AS city,
        a.ca_state AS state,
        a.unique_addresses,
        d.total_customers,
        d.avg_dependents,
        d.marital_status_list,
        s.total_sales,
        s.avg_profit
    FROM
        address_summary a
    JOIN demographics_summary d ON (a.ca_state = d.cd_gender)
    JOIN sales_summary s ON (s.cs_item_sk = a.unique_addresses)
    ORDER BY
        a.unique_addresses DESC
)
SELECT
    city,
    state,
    unique_addresses,
    total_customers,
    avg_dependents,
    marital_status_list,
    total_sales,
    avg_profit
FROM
    final_report
WHERE
    unique_addresses > 10
ORDER BY
    total_sales DESC;
