
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
), 
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_week_seq,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
)
SELECT 
    ci.full_name,
    ci.cd_marital_status,
    ci.cd_gender,
    d.d_date,
    sd.total_orders,
    sd.total_revenue,
    CASE 
        WHEN ci.cd_purchase_estimate IS NOT NULL THEN 
            ROUND(sd.total_revenue / ci.cd_purchase_estimate, 2)
        ELSE 
            NULL 
    END AS revenue_to_estimate_ratio
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = CAST(sd.ws_ship_date_sk AS CHAR) -- assuming ws_ship_date_sk correlates with customer_id in some way for this example
JOIN 
    DateInfo d ON sd.ws_ship_date_sk = d.d_date_sk
WHERE 
    ci.ca_state = 'NY' 
    AND d.d_year = 2022
ORDER BY 
    sd.total_revenue DESC;
