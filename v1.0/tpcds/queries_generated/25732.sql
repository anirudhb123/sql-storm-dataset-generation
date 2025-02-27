
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
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
Purchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
DemographicsAnalysis AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        COALESCE(p.total_orders, 0) AS total_orders,
        COALESCE(p.total_spent, 0) AS total_spent,
        COALESCE(p.avg_order_value, 0) AS avg_order_value
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        Purchases p ON ci.c_customer_id = p.c_customer_id
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(d.total_spent) AS average_spending,
    AVG(d.avg_order_value) AS average_order_value
FROM 
    DemographicsAnalysis d
JOIN 
    customer_demographics cd ON 
        (cd.cd_gender = d.cd_gender AND cd.cd_marital_status = d.cd_marital_status)
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;
