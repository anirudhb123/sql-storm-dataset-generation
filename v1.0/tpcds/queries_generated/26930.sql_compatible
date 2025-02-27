
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        REPLACE(ca_zip, '-', '') AS cleaned_zip
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        MIN(cd_dep_count) AS min_dependents,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
FinalMetrics AS (
    SELECT 
        d.cd_demo_sk,
        d.customer_count,
        d.min_dependents,
        d.max_dependents,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders
    FROM 
        Demographics d
    LEFT JOIN 
        SalesData s ON d.cd_demo_sk = s.ws_bill_cdemo_sk
)
SELECT 
    f.cd_demo_sk,
    f.customer_count,
    f.min_dependents,
    f.max_dependents,
    f.total_sales,
    f.total_orders,
    CONCAT('Address Count: ', COUNT(a.ca_address_sk)) AS address_count_summary,
    STRING_AGG(a.full_address, '; ') AS all_addresses
FROM 
    FinalMetrics f
LEFT JOIN 
    AddressDetails a ON a.ca_address_sk IN (SELECT c_current_addr_sk FROM customer WHERE c_current_cdemo_sk = f.cd_demo_sk)
GROUP BY 
    f.cd_demo_sk, f.customer_count, f.min_dependents, f.max_dependents, f.total_sales, f.total_orders
ORDER BY 
    f.total_sales DESC;
