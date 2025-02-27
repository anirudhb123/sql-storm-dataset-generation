
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_email_address,
        cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
AggregatedData AS (
    SELECT 
        cd.customer_id,
        ad.full_address,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sd.total_orders,
        sd.total_revenue
    FROM CustomerDetails cd
    LEFT JOIN AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.customer_id
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_marital_status,
    COALESCE(total_orders, 0) AS order_count,
    COALESCE(total_revenue, 0) AS revenue,
    (CASE 
        WHEN total_revenue > 10000 THEN 'High Value'
        WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END) AS customer_value_category
FROM AggregatedData
ORDER BY revenue DESC
LIMIT 100;
