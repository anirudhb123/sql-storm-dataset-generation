
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(ws.order_number) AS order_count
    FROM web_sales ws 
    GROUP BY ws.bill_customer_sk
),
AggregatedSales AS (
    SELECT
        cd.c_customer_sk,
        cd.full_name,
        ad.full_address,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM CustomerDetails cd
    LEFT JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesDetails sd ON cd.c_customer_sk = sd.bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM AggregatedSales
WHERE total_sales > 0
ORDER BY total_sales DESC
LIMIT 100;
