
WITH AddressExtract AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number) AS full_address,
        LENGTH(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number)) AS address_length
    FROM customer_address
), SalesSummary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_date_sk = t.d_date_sk
    WHERE t.d_year = 2023
    GROUP BY ss.s_store_sk
), Benchmark AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        a.address_length,
        s.total_sales,
        s.total_quantity,
        s.unique_customers
    FROM AddressExtract a
    LEFT JOIN SalesSummary s ON a.ca_address_sk = s.s_store_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales > 100000 THEN 'High Sales'
        WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM Benchmark
ORDER BY address_length DESC, total_sales DESC
LIMIT 100;
