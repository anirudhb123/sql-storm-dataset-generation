
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), RankedCustomers AS (
    SELECT 
        ci.*, 
        STRING_AGG(CONCAT(DISTINCT wp.wp_url), ', ') AS customer_web_visits
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_page wp ON ci.c_customer_id = wp.wp_customer_sk
    WHERE 
        ci.rank <= 10
    GROUP BY 
        ci.c_customer_id, ci.full_name, ci.ca_city, ci.ca_state, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate, ci.cd_credit_rating
)
SELECT
    *
FROM
    RankedCustomers
ORDER BY 
    ca_city, cd_purchase_estimate DESC;
