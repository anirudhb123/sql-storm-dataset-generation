
WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
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
date_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MIN(d.d_date) AS first_order_date,
        MAX(d.d_date) AS last_order_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_bill_customer_sk
),
customer_benchmark AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        ds.total_sales,
        ds.order_count,
        ds.first_order_date,
        ds.last_order_date,
        DATEDIFF(ds.last_order_date, ds.first_order_date) AS order_duration
    FROM 
        customer_details cd
    LEFT JOIN 
        date_sales ds ON cd.c_customer_sk = ds.ws_bill_customer_sk
)
SELECT 
    cb.full_name,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.total_sales,
    cb.order_count,
    cb.order_duration,
    CASE 
        WHEN cb.order_duration > 365 THEN 'Active'
        WHEN cb.order_duration BETWEEN 180 AND 365 THEN 'Moderate'
        WHEN cb.order_duration < 180 THEN 'Inactive'
        ELSE 'No Orders'
    END AS customer_status
FROM 
    customer_benchmark cb
WHERE 
    cb.total_sales > 1000
ORDER BY 
    cb.total_sales DESC;
