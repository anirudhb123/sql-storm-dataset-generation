
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        ca.city,
        ca.state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        c.email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
OrderStats AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.gender,
        ci.marital_status,
        ci.education_status,
        ci.city,
        ci.state,
        ci.full_address,
        ci.email_address,
        os.total_orders,
        os.total_profit
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        OrderStats os ON ci.c_customer_sk = os.bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_profit > 1000 THEN 'High Value Customer' 
        WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_profit DESC, total_orders DESC;
