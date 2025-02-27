
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year,
        d.d_holiday,
        d.d_weekend
    FROM 
        date_dim d
    WHERE 
        d.d_date >= '2023-01-01' AND d.d_date < '2024-01-01'
),
SalesInfo AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    di.d_date,
    di.d_day_name,
    di.d_month_seq,
    di.d_year,
    si.total_net_profit
FROM 
    CustomerInfo ci
JOIN 
    DateInfo di ON di.d_date_sk IN (
        SELECT DISTINCT ws_ship_date_sk
        FROM web_sales
        WHERE ws_bill_customer_sk = ci.c_customer_sk
    )
LEFT JOIN 
    SalesInfo si ON si.ws_ship_date_sk = di.d_date_sk
WHERE 
    (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M')
ORDER BY 
    total_net_profit DESC, ci.full_name ASC;
