
WITH formatted_addresses AS (
    SELECT
        ca_address_id,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_suite_number, ca_city, ca_state, ca_zip) AS full_address,
        TRIM(CONCAT(UPPER(LEFT(ca_street_name, 1)), LOWER(SUBSTRING(ca_street_name, 2)))) AS formatted_street_name
    FROM
        customer_address
),
demographics AS (
    SELECT
        cd_gender,
        COUNT(*) AS gender_count,
        STRING_AGG(cd_marital_status || ' - ' || cd_education_status, '; ') AS marital_education_group
    FROM
        customer_demographics
    GROUP BY
        cd_gender
),
item_sales AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_id
),
store_summary AS (
    SELECT
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_net_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_name
)
SELECT
    fa.ca_address_id,
    fa.full_address,
    d.cd_gender,
    d.gender_count,
    d.marital_education_group,
    is.total_sales_quantity,
    is.total_revenue,
    ss.s_store_name,
    ss.total_net_sales,
    ss.total_transactions
FROM
    formatted_addresses fa
JOIN
    demographics d ON d.cd_gender = 'F'  -- Just an example filter
JOIN
    item_sales is ON is.i_item_id LIKE '%A%'  -- Just an example filter
JOIN
    store_summary ss ON ss.total_net_sales > 1000  -- Just an example filter
ORDER BY
    fa.ca_address_id, d.gender_count DESC, is.total_revenue DESC
LIMIT 100;
