
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
PurchaseStats AS (
    SELECT 
        ci.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        CustomerInfo ci
    JOIN 
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_id
),
GenderStats AS (
    SELECT 
        ci.cd_gender,
        COUNT(*) AS customer_count,
        SUM(ps.total_orders) AS total_orders,
        SUM(ps.total_spent) AS total_spent,
        AVG(ps.avg_order_value) AS avg_order_value_per_gender
    FROM 
        CustomerInfo ci
    JOIN 
        PurchaseStats ps ON ci.c_customer_id = ps.c_customer_id
    GROUP BY 
        ci.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.customer_count,
    gs.total_orders,
    gs.total_spent,
    gs.avg_order_value_per_gender,
    RANK() OVER (ORDER BY gs.total_spent DESC) AS spend_rank
FROM 
    GenderStats gs
ORDER BY 
    gs.total_spent DESC;
