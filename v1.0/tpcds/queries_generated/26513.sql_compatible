
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        c.c_email_address,
        COALESCE(NULLIF(c.c_email_address, ''), 'No Email') AS email_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), DateRange AS (
    SELECT 
        MIN(d.d_date) AS start_date,
        MAX(d.d_date) AS end_date
    FROM 
        date_dim d
    WHERE 
        d.d_date >= '2023-01-01' AND d.d_date <= '2023-12-31'
), SalesData AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        DateRange dr ON ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = dr.start_date) 
                                          AND (SELECT d_date_sk FROM date_dim WHERE d_date = dr.end_date)
), ProcessedData AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        sd.total_sales,
        sd.total_orders,
        sd.unique_customers
    FROM 
        CustomerInfo ci
    CROSS JOIN 
        SalesData sd
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_orders,
    unique_customers,
    CASE 
        WHEN total_sales > 10000 THEN 'High Revenue Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    LENGTH(full_name) AS name_length,
    UPPER(cd_gender) AS gender_uppercase
FROM 
    ProcessedData
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;
