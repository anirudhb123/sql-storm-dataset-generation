
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
BenchmarkData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) > 10000 THEN 'High Value'
            WHEN COALESCE(sd.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ca_state,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_value,
    AVG(total_sales) AS avg_sales_per_customer,
    MAX(total_sales) AS max_sales_value,
    MIN(total_sales) AS min_sales_value,
    LISTAGG(full_name, ', ') AS customer_names
FROM BenchmarkData
GROUP BY ca_state
ORDER BY total_sales_value DESC;
