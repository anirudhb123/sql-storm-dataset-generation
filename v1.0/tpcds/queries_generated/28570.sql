
WITH string_aggregation AS (
    SELECT
        ca_state,
        LISTAGG(ca_street_name, '; ') WITHIN GROUP (ORDER BY ca_street_name) AS aggregated_street_names,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM
        customer_address
    GROUP BY
        ca_state
),
customer_details AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_demographics
    JOIN
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY
        cd_gender,
        cd_marital_status
),
sales_summary AS (
    SELECT
        d_year,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY
        d_year
)
SELECT
    a.ca_state,
    a.aggregated_street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.customer_count,
    s.total_net_profit
FROM
    string_aggregation a
JOIN
    customer_details c ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = c.ct_demo_sk LIMIT 1)
JOIN
    sales_summary s ON s.d_year = (SELECT d_year FROM date_dim LIMIT 1)
ORDER BY
    a.ca_state;
