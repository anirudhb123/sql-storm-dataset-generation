
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ca.ca_city, 
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ws.ws_sold_date_sk, 
        ci.full_name, 
        ci.ca_city, 
        ci.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
),
SalesSummary AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        SUM(ws_sales_price) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_order_value
    FROM 
        SalesData
    GROUP BY 
        full_name, ca_city, ca_state
)
SELECT 
    full_name, 
    ca_city, 
    ca_state,
    total_orders,
    total_spent,
    avg_order_value,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM 
    SalesSummary
WHERE 
    total_orders > 1
ORDER BY 
    spending_rank;
