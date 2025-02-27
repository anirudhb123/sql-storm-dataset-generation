
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ss.total_sales,
        ss.total_orders,
        ss.last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
),
address_info AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.last_purchase_date,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ai.ca_city,
    ai.ca_state,
    ai.ca_country
FROM 
    top_customers tc
JOIN 
    address_info ai ON tc.c_customer_id = ai.c_customer_id
ORDER BY 
    tc.total_sales DESC;
