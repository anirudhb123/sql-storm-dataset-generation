
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
GenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_dep_count) AS average_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        'WS' AS source,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'SS' AS source,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_orders,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM 
        store_sales
)
SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    gs.cd_gender,
    gs.gender_count,
    gs.average_dependencies,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers
FROM 
    AddressDetails ad
JOIN 
    GenderStats gs ON gs.gender_count > 5
JOIN 
    (SELECT 
        SUM(total_sales) AS grand_total_sales,
        SUM(total_orders) AS grand_total_orders,
        SUM(unique_customers) AS grand_unique_customers
     FROM SalesStats) ss ON ss.grand_total_sales > 100000
WHERE 
    ad.ca_state = 'CA'
ORDER BY 
    ad.ca_city, ss.total_sales DESC
LIMIT 50;
