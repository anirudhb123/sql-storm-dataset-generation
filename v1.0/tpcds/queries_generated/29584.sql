
WITH AddressDetails AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS full_address,
        ca.zip AS address_zip,
        ca.country AS address_country
    FROM customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.first_name,
        c.last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_dependency_count AS dependents,
        d.cd_purchase_estimate AS estimated_purchase,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws.bill_customer_sk AS customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
)
SELECT 
    c.full_name,
    a.address_city,
    a.address_state,
    a.address_zip,
    a.address_country,
    ROUND(s.total_sales, 2) AS total_sales_amount,
    s.order_count AS total_orders,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        WHEN s.total_sales < 500 THEN 'Low Value Customer'
        WHEN s.total_sales >= 500 AND s.total_sales < 2000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM CustomerDetails c
JOIN AddressDetails a ON c.c_customer_sk = a.c_customer_sk
LEFT JOIN SalesSummary s ON c.c_customer_sk = s.customer_sk
WHERE a.address_city IS NOT NULL
ORDER BY total_sales_amount DESC;
