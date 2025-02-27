
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedReturns AS (
    SELECT 
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amount) AS total_return_value,
        c.c_customer_id,
        c.ca_city,
        c.ca_state
    FROM 
        store_returns sr
    JOIN 
        CustomerInfo c ON sr.sr_customer_sk = CAST(c.c_customer_id AS INTEGER)
    GROUP BY 
        c.c_customer_id, c.ca_city, c.ca_state
)
SELECT 
    ci.c_customer_id,
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ir.trigger_value,
    COALESCE(ar.total_returns, 0) AS total_returns,
    COALESCE(ar.total_return_value, 0) AS total_return_value
FROM 
    CustomerInfo ci
LEFT JOIN 
    AggregatedReturns ar ON ci.c_customer_id = ar.c_customer_id
JOIN 
    (SELECT 
        ca.city || ', ' || ca.state AS trigger_value 
     FROM 
        customer_address ca 
     WHERE 
        LENGTH(ca.ca_zip) = 5) ir ON ci.ca_city || ', ' || ci.ca_state = ir.trigger_value
ORDER BY 
    ci.c_customer_id;
