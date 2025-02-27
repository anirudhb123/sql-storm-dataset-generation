
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
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
SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
AggregatedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    total_profit,
    total_orders,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value'
        WHEN total_profit > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    AggregatedData
WHERE 
    ca_country = 'USA'
ORDER BY 
    total_profit DESC, 
    full_name ASC
LIMIT 100;
