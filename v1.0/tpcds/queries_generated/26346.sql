
WITH Customer_Details AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
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
Sales_Statistics AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Enhanced_Customer_Sales AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_spent, 0) AS total_spent,
        COALESCE(ss.avg_order_value, 0) AS avg_order_value
    FROM 
        Customer_Details cd
    LEFT JOIN 
        Sales_Statistics ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_orders,
    total_spent,
    avg_order_value,
    CONCAT(ECAST(total_spent AS varchar), ' USD') AS formatted_total_spent,
    CASE 
        WHEN total_orders > 0 THEN 'Active Customer'
        ELSE 'Inactive Customer'
    END AS customer_status
FROM 
    Enhanced_Customer_Sales
ORDER BY 
    total_spent DESC
LIMIT 100;
