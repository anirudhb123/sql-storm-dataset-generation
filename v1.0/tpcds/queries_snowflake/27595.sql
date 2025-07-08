
WITH address_info AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        LISTAGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') WITHIN GROUP (ORDER BY ca_street_name, ca_street_type) AS unique_street_names
    FROM customer_address
    GROUP BY ca_city, ca_state
),
demographic_info AS (
    SELECT 
        cd_marital_status,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_marital_status
),
sales_info AS (
    SELECT 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue
    FROM web_sales
),
final_summary AS (
    SELECT 
        ai.ca_city,
        ai.ca_state,
        ai.address_count,
        ai.unique_street_names,
        di.cd_marital_status,
        di.demographic_count,
        di.avg_purchase_estimate,
        si.total_quantity,
        si.total_revenue
    FROM address_info ai
    JOIN demographic_info di ON SUBSTR(ai.ca_city, 1, 3) = SUBSTR(di.cd_marital_status, 1, 3)
    CROSS JOIN sales_info si
)
SELECT 
    ca_city,
    ca_state,
    address_count,
    unique_street_names,
    cd_marital_status,
    demographic_count,
    avg_purchase_estimate,
    total_quantity,
    total_revenue
FROM final_summary
ORDER BY ca_city, ca_state, cd_marital_status;
