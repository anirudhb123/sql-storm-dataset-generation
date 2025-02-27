
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        wd.ws_bill_customer_sk, 
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS average_order_value
    FROM 
        web_sales wd
    GROUP BY 
        wd.ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.average_order_value, 0) AS average_order_value
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_orders,
    total_sales,
    average_order_value,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    FinalBenchmark
ORDER BY 
    total_sales DESC
LIMIT 100;
