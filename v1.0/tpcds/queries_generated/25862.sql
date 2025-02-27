
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
            CASE 
                WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', ca_suite_number) 
                ELSE '' 
            END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
WebSalesData AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit,
        ws_ship_date_sk,
        ws_web_site_sk
    FROM web_sales
),
TotalSales AS (
    SELECT 
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM WebSalesData
    GROUP BY ws_web_site_sk
)
SELECT 
    a.full_address,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_profit, 0) AS total_profit,
    COALESCE(s.order_count, 0) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY s.ws_web_site_sk ORDER BY s.total_sales DESC) AS sales_rank
FROM AddressDetails a
JOIN CustomerDetails c ON a.ca_address_sk = c.c_customer_sk
LEFT JOIN TotalSales s ON s.ws_web_site_sk = a.ca_state
WHERE a.ca_country = 'USA'
ORDER BY total_sales DESC, total_profit DESC;
