
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
average_order AS (
    SELECT 
        c.c_customer_id,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        avg_order.average_order_value
    FROM 
        top_customers tc
    JOIN 
        customer c ON tc.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        average_order avg_order ON c.c_customer_id = avg_order.c_customer_id
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.average_order_value,
    SUM(ws.ws_quantity) AS total_items_purchased,
    COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
FROM 
    customer_details cd
JOIN 
    web_sales ws ON cd.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    cd.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.average_order_value
ORDER BY 
    cd.average_order_value DESC;
