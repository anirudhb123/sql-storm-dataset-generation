
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_id = sd.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > 1000 THEN 'High-Value Customer' 
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium-Value Customer' 
        ELSE 'Low-Value Customer' 
    END AS customer_value_segment
FROM 
    CombinedData
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;
