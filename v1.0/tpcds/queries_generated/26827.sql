
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city, 
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
),
CustomerHighlights AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        ch.customer_name,
        ch.cd_gender,
        ch.cd_marital_status,
        ch.cd_purchase_estimate,
        ad.full_address,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        CustomerHighlights ch
    LEFT JOIN 
        SalesData sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_orders > 50 THEN 'High Activity'
        WHEN total_orders BETWEEN 10 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM 
    FinalBenchmark
WHERE 
    cd_gender = 'F' AND cd_purchase_estimate > 10000
ORDER BY 
    total_profit DESC, customer_name ASC
LIMIT 100;
