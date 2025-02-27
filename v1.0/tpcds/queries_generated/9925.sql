
WITH customer_spending AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_spending cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_spending)
),
customer_addresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_customer_id IN (SELECT c_customer_id FROM high_value_customers)
),
sales_summary AS (
    SELECT 
        cu.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    JOIN 
        high_value_customers cu ON ws.ws_bill_customer_sk = 
[__INSERT_CUSTOMER_SK_MAPPING__]
    GROUP BY 
        cu.c_customer_id
)
SELECT 
    hvc.c_customer_id,
    hvc.total_spent,
    hvc.total_orders,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ss.total_quantity_sold,
    ss.total_sales_value
FROM 
    high_value_customers hvc
JOIN 
    customer_addresses ca ON hvc.c_customer_id = ca.c_customer_id
JOIN 
    sales_summary ss ON hvc.c_customer_id = ss.c_customer_id
ORDER BY 
    total_spent DESC;
