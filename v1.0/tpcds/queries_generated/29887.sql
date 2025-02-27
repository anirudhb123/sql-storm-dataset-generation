
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateInfo AS (
    SELECT 
        d.d_date AS order_date,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(cd.cd_dep_count) AS average_dependents,
    di.d_year,
    di.d_month_seq
FROM 
    CustomerInfo ci
JOIN 
    web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    DateInfo di ON ws.ws_sold_date_sk = di.d_date_sk
WHERE 
    ci.cd_gender = 'M'
    AND ci.cd_marital_status = 'S'
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state, ci.cd_gender, ci.cd_marital_status, di.d_year, di.d_month_seq
ORDER BY 
    total_profit DESC, ci.full_name
LIMIT 100;
