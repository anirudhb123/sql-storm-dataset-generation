
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_number,
        CONCAT(ca.ca_street_name, ' ', ca.ca_street_type) AS full_street,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.cd_dep_count,
        ai.full_street,
        ai.ca_city,
        ai.ca_state,
        ai.ca_zip,
        ai.ca_country,
        COALESCE(si.total_profit, 0) AS total_profit
    FROM 
        customer_info ci
        JOIN address_info ai ON ci.c_customer_id = ai.ca_address_id
        LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    full_street,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    total_profit
FROM 
    combined_info
WHERE 
    total_profit > 1000
ORDER BY 
    total_profit DESC
LIMIT 100;
