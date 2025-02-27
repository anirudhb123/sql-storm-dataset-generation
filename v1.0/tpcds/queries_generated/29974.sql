
WITH Address_Stats AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(LENGTH(ca_street_name)) AS max_street_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_length
    FROM
        customer_address
    GROUP BY
        ca_state
),
Customer_Analysis AS (
    SELECT
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
Sales_Stats AS (
    SELECT
        'Web' AS sale_channel,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    UNION ALL
    SELECT
        'Store' AS sale_channel,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS order_count
    FROM
        store_sales
)
SELECT
    a.ca_state,
    a.unique_addresses,
    a.max_street_length,
    a.avg_street_length,
    c.cd_gender,
    c.customer_count,
    c.avg_purchase_estimate,
    c.total_dependents,
    s.sale_channel,
    s.total_sales,
    s.order_count
FROM
    Address_Stats a
JOIN
    Customer_Analysis c ON c.customer_count > 1000
JOIN
    Sales_Stats s ON s.total_sales > 10000
ORDER BY
    a.unique_addresses DESC, c.customer_count DESC, s.total_sales DESC;
