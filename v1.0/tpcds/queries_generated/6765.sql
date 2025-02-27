
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),

sales_analysis AS (
    SELECT
        ci.ca_city,
        ci.ca_state,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.ca_city, ci.ca_state
)

SELECT 
    cust.c_first_name,
    cust.c_last_name,
    cust.cd_gender,
    cust.cd_marital_status,
    cust.cd_education_status,
    sales.total_quantity_sold,
    sales.average_sales_price,
    sales.total_orders
FROM 
    customer_data cust
JOIN 
    sales_analysis sales ON cust.c_customer_sk = sales.c_customer_sk
WHERE 
    cust.order_count > 0
ORDER BY 
    total_spent DESC, cust.c_last_name, cust.c_first_name
LIMIT 100;
