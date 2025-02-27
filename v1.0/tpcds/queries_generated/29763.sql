
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),

CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
),

Sales AS (
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
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        sa.total_profit,
        sa.total_orders,
        ad.full_address
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        Sales sa ON cd.c_customer_sk = sa.ws_bill_customer_sk
    LEFT JOIN 
        AddressDetails ad ON ad.ca_address_sk = cd.c_current_addr_sk
    WHERE 
        cd.cd_purchase_estimate > 500
        AND ad.ca_state = 'CA'
)

SELECT 
    *,
    CASE 
        WHEN total_profit IS NULL THEN 'No purchases yet'
        ELSE CONCAT('Total Profit: $', FORMAT(total_profit, 2))
    END AS profit_message
FROM 
    FinalBenchmark
ORDER BY 
    total_profit DESC;
