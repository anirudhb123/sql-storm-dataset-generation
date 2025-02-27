
WITH AddressSegments AS (
    SELECT 
        ca_address_sk,
        LOWER(TRIM(ca_street_name)) AS street_name_lower,
        TRIM(ca_city) AS city_trimmed,
        TRIM(ca_state) AS state_trimmed,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)) AS full_address
    FROM 
        customer_address
),
DistinctCities AS (
    SELECT DISTINCT 
        city_trimmed,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        AddressSegments
    WHERE 
        LENGTH(street_name_lower) > 0
    GROUP BY 
        city_trimmed
),
CustomerPurchaseStats AS (
    SELECT 
        cd_demo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk
),
DemographicAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(total_sales) AS avg_sales,
        SUM(order_count) AS total_orders
    FROM 
        CustomerPurchaseStats
    JOIN 
        customer_demographics ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.avg_sales,
    da.total_orders,
    dc.city_trimmed,
    dc.address_count
FROM 
    DemographicAnalysis da
JOIN 
    DistinctCities dc ON da.avg_sales > 1000
ORDER BY 
    da.avg_sales DESC, dc.address_count DESC
LIMIT 50;
