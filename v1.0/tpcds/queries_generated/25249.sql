
WITH AddressInfo AS (
    SELECT 
        ca_city,
        UPPER(TRIM(ca_street_name)) AS formatted_street_name,
        CONCAT(ca_street_number, ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        LENGTH(TRIM(ca_street_name)) AS street_name_length
    FROM customer_address 
    WHERE ca_state = 'CA'
),
CustomerInfo AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, cd_marital_status, cd_education_status, cd_dep_count
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    a.ca_city,
    a.formatted_street_name,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(s.total_sales) AS total_web_sales,
    AVG(s.order_count) AS average_orders_per_customer,
    AVG(a.street_name_length) AS avg_street_name_length
FROM AddressInfo a
JOIN CustomerInfo c ON a.ca_city = (
    SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk
)
JOIN SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
GROUP BY a.ca_city, a.formatted_street_name
ORDER BY total_web_sales DESC, total_customers DESC;
