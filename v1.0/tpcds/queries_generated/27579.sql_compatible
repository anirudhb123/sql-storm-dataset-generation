
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
BenchmarkData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        si.total_profit,
        si.total_orders,
        (si.total_profit / NULLIF(si.total_orders, 0)) AS avg_profit_per_order
    FROM 
        CustomerInfo AS ci
    LEFT JOIN 
        SalesData AS si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    cd.cd_gender,
    COUNT(*) AS customer_count,
    AVG(bd.avg_profit_per_order) AS avg_profit_per_customer
FROM 
    BenchmarkData AS bd
JOIN 
    customer_demographics AS cd ON bd.cd_gender = cd.cd_gender
GROUP BY 
    cd.cd_gender
ORDER BY 
    customer_count DESC;
