
WITH AddressComponents AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS location,
        ca_country
    FROM customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalOutput AS (
    SELECT 
        c.full_name,
        a.full_address,
        a.location,
        a.ca_country,
        ci.total_sales,
        ci.order_count,
        CASE 
            WHEN ci.total_sales IS NULL THEN 'No Sales'
            WHEN ci.total_sales < 1000 THEN 'Low Sales'
            WHEN ci.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM CustomerInfo c
    LEFT JOIN SalesInfo ci ON c.c_customer_sk = ci.ws_bill_customer_sk
    LEFT JOIN AddressComponents a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    full_name,
    full_address,
    location,
    ca_country,
    total_sales,
    order_count,
    sales_category
FROM FinalOutput
WHERE location LIKE '%New York%'
ORDER BY total_sales DESC;
