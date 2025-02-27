
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
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
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM CustomerDetails cd
    LEFT JOIN SalesData sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales > 5000 THEN 'High Value'
        WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM FinalReport
ORDER BY total_sales DESC;
