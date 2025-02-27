
WITH AddressedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent,
        AVG(ws_net_paid) AS avg_spent_per_order
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ac.customer_name,
    ac.full_address,
    ac.cd_gender,
    ac.cd_marital_status,
    ac.cd_education_status,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.avg_spent_per_order, 0) AS avg_spent_per_order
FROM 
    AddressedCustomers ac
LEFT JOIN 
    SalesData sd ON ac.c_customer_id = sd.ws_bill_customer_sk
ORDER BY 
    total_spent DESC
LIMIT 100;
