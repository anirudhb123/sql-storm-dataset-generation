
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
income_ranges AS (
    SELECT 
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5001 AND 15000 THEN 'Medium'
            WHEN cd.cd_purchase_estimate > 15000 THEN 'High'
        END AS income_band,
        COUNT(*) AS customer_count
    FROM customer_info ci
    GROUP BY 1
),
most_common_states AS (
    SELECT 
        ca.ca_state,
        COUNT(*) AS state_count
    FROM customer_info ci
    JOIN customer_address ca ON ci.c_customer_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
    ORDER BY state_count DESC
    LIMIT 5
)
SELECT 
    ir.income_band,
    ir.customer_count,
    mc.ca_state,
    mc.state_count
FROM income_ranges ir
CROSS JOIN most_common_states mc
ORDER BY ir.income_band, mc.state_count DESC;
