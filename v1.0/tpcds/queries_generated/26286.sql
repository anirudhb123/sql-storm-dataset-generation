
WITH AddressDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        full_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM AddressDetails ad
    JOIN web_sales ws ON ad.c_customer_id = ws.ws_ship_customer_sk
    GROUP BY full_name
),
GenderSummary AS (
    SELECT 
        ad.cd_gender,
        SUM(ss.ss_ext_sales_price) AS gender_sales
    FROM AddressDetails ad
    JOIN store_sales ss ON ad.c_customer_id = ss.ss_customer_sk
    GROUP BY ad.cd_gender
),
FinalBenchmark AS (
    SELECT 
        ad.full_name,
        ad.total_sales,
        CASE 
            WHEN ad.total_sales > 10000 THEN 'High Value'
            WHEN ad.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        gs.gender_sales
    FROM SalesSummary ad
    LEFT JOIN GenderSummary gs ON 1=1
)
SELECT 
    fb.full_name,
    fb.total_sales,
    fb.customer_value,
    gs.cd_gender,
    fb.total_orders
FROM FinalBenchmark fb
JOIN AddressDetails ad ON fb.full_name = ad.full_name
ORDER BY fb.total_sales DESC, ad.cd_gender;
