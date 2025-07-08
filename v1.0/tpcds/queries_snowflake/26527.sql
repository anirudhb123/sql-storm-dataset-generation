
WITH string_aggregates AS (
    SELECT
        ca_state,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(LENGTH(c_first_name) + LENGTH(c_last_name)) AS total_name_length,
        AVG(LENGTH(c_email_address)) AS avg_email_length,
        LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') WITHIN GROUP (ORDER BY CONCAT(c_first_name, ' ', c_last_name)) AS aggregated_names
    FROM
        customer_address AS ca
    JOIN
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE
        ca_state IN ('CA', 'TX', 'NY')
    GROUP BY
        ca_state
),
demographics_summary AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_demographics
    GROUP BY
        cd_gender
)
SELECT
    sa.ca_state,
    sa.unique_customers,
    sa.total_name_length,
    sa.avg_email_length,
    sa.aggregated_names,
    ds.cd_gender,
    ds.demographic_count,
    ds.avg_purchase_estimate
FROM
    string_aggregates sa
JOIN
    demographics_summary ds ON 1 = 1 
ORDER BY
    sa.ca_state, ds.cd_gender;
