
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name 
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_first_name
            ELSE c.c_first_name
        END AS salutation,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.full_name,
        c.city,
        c.state,
        c.salutation,
        c.cd_purchase_estimate
    FROM 
        customer_info c
    WHERE 
        c.rank <= 5
)

SELECT 
    t.full_name,
    t.city,
    t.state,
    t.salutation,
    t.cd_purchase_estimate
FROM 
    top_customers t
JOIN 
    income_band ib ON t.cd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ib.ib_upper_bound > 50000
ORDER BY 
    t.state, t.cd_purchase_estimate DESC;
