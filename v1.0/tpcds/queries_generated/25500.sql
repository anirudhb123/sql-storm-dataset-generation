
WITH AddressStats AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1) AS word_count,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM
        customer_address
    GROUP BY
        ca_city,
        ca_state
),
CustomerStats AS (
    SELECT
        CONCAT(cd_gender, '-', cd_marital_status) AS demographic_group,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependency_count
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        CONCAT(cd_gender, '-', cd_marital_status)
),
SalesStats AS (
    SELECT
        EXTRACT(YEAR FROM d_date) AS sale_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        EXTRACT(YEAR FROM d_date)
),
FinalReport AS (
    SELECT
        a.ca_city,
        a.ca_state,
        a.unique_addresses,
        c.demographic_group,
        c.customer_count,
        c.total_purchase_estimate,
        s.sale_year,
        s.total_sales,
        s.total_net_profit,
        (a.word_count * c.customer_count) AS weighted_word_count
    FROM
        AddressStats a
    JOIN
        CustomerStats c ON a.ca_state = CurrentCityState -- Replace with appropriate state matching logic
    JOIN
        SalesStats s ON s.sale_year = YEAR(CURRENT_DATE()) -- Adjust year as necessary
)
SELECT
    *
FROM
    FinalReport
ORDER BY
    unique_addresses DESC, total_sales DESC;
