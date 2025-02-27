
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS total_addresses, 
        SUM(CASE 
            WHEN ca_street_name LIKE '%St%' THEN 1 
            ELSE 0 
        END) AS count_street_st,
        SUM(CASE 
            WHEN ca_street_name LIKE '%Ave%' THEN 1 
            ELSE 0 
        END) AS count_street_ave,
        SUM(CASE 
            WHEN ca_street_name LIKE '%Blvd%' THEN 1 
            ELSE 0 
        END) AS count_street_blvd,
        AVG(LENGTH(ca_street_name)) AS avg_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS total_customers, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        COUNT(DISTINCT cd_credit_rating) AS unique_credit_ratings
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DailySales AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.count_street_st,
    a.count_street_ave,
    a.count_street_blvd,
    a.avg_street_length,
    d.cd_gender,
    d.total_customers,
    d.avg_purchase_estimate,
    d.avg_dependents,
    d.unique_credit_ratings,
    s.sale_date,
    s.total_net_profit,
    s.total_orders,
    s.avg_discount
FROM 
    AddressStats a
JOIN 
    DemographicStats d ON 1=1
JOIN 
    DailySales s ON s.sale_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    a.total_addresses DESC, d.total_customers DESC, s.total_net_profit DESC;
