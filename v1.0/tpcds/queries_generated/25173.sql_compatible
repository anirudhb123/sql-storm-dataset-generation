
WITH address_summary AS (
    SELECT
        ca_state,
        COUNT(ca_address_sk) AS total_addresses,
        STRING_AGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_address_list
    FROM
        customer_address
    GROUP BY
        ca_state
),

demographic_summary AS (
    SELECT
        cd_gender,
        COUNT(cd_demo_sk) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(cd_marital_status, ', ') AS marital_status_list
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),

sales_summary AS (
    SELECT
        d_year,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_net_paid) AS total_revenue,
        STRING_AGG(i_item_desc, '; ') AS items_sold
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    JOIN
        item ON ws_item_sk = i_item_sk
    GROUP BY
        d_year
)

SELECT
    a.ca_state,
    a.total_addresses,
    a.full_address_list,
    d.cd_gender,
    d.demographic_count,
    d.avg_purchase_estimate,
    d.marital_status_list,
    s.d_year,
    s.total_sales,
    s.total_revenue,
    s.items_sold
FROM
    address_summary a
JOIN
    demographic_summary d ON a.total_addresses > 1000
JOIN
    sales_summary s ON s.total_sales > 5000
ORDER BY
    a.ca_state, d.cd_gender, s.d_year DESC;
