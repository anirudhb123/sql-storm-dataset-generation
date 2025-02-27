
WITH EnhancedCustomerAddress AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_gmt_offset
    FROM customer_address
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_credit_rating LIKE 'Excellent%' THEN 'High'
            WHEN cd_credit_rating LIKE 'Good%' THEN 'Medium'
            ELSE 'Low'
        END AS credit_category,
        cd_dep_count
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
JoinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.full_address,
        cd.cd_gender,
        cd.credit_category,
        sd.total_sales,
        sd.order_count
    FROM customer c
    JOIN EnhancedCustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN FilteredDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    full_address,
    gender,
    credit_category,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count
FROM JoinedData
WHERE credit_category = 'High'
ORDER BY total_sales DESC
LIMIT 10;
