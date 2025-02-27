
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalData AS (
    SELECT 
        cd.full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.ca_city, 
        cd.ca_state, 
        cd.ca_country, 
        cd.ca_zip, 
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    total_sales,
    order_count,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalData
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC;
