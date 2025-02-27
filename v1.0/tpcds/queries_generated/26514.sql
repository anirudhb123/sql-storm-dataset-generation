
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        a.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(ws_order_number) AS order_count 
    FROM web_sales 
    GROUP BY ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        cd.ca_zip,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM CustomerDetails cd
    LEFT JOIN SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM FinalBenchmark
ORDER BY total_sales DESC
LIMIT 100;
