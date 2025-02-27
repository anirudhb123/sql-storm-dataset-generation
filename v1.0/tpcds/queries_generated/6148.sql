
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id
), 
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
) 
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    caddr.ca_city,
    caddr.ca_state,
    cct.cc_name
FROM 
    top_customers tc
JOIN 
    customer_address caddr ON caddr.ca_address_sk = c.c_current_addr_sk
JOIN 
    call_center cct ON cct.cc_call_center_sk = c.c_current_cdemo_sk
WHERE 
    caddr.ca_state IN ('CA', 'NY')
ORDER BY 
    tc.total_sales DESC;
