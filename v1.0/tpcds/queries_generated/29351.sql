
WITH Customer_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' 
),
Sales_Info AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MIN(ws.ws_sold_date_sk) AS first_order_date,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
Combined_Info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        si.total_sales,
        si.order_count,
        DATEDIFF(si.last_order_date, si.first_order_date) AS order_duration_days,
        ci.customer_value
    FROM 
        Customer_Info ci
    JOIN 
        Sales_Info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.total_sales,
    ci.order_count,
    ci.order_duration_days,
    ci.customer_value
FROM 
    Combined_Info ci
WHERE 
    ci.total_sales > 2000 AND 
    ci.order_duration_days <= 365
ORDER BY 
    ci.total_sales DESC;
