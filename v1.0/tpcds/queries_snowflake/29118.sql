
WITH AddressGroups AS (
    SELECT
        ca_city,
        ca_state,
        LISTAGG(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), ', ') AS full_address
    FROM
        customer_address
    GROUP BY
        ca_city, ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        LISTAGG(DISTINCT cd_education_status, ', ') AS unique_education_levels
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender
)
SELECT
    ag.ca_city,
    ag.ca_state,
    ag.full_address,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.unique_education_levels
FROM
    AddressGroups ag
JOIN
    CustomerStats cs ON ag.ca_state = cs.cd_gender
ORDER BY
    ag.ca_state, ag.ca_city, cs.cd_gender;
