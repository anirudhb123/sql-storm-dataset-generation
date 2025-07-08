
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        SUM(CASE WHEN ca_city ILIKE '%ville%' THEN 1 ELSE 0 END) AS city_with_ville_count,
        ARRAY_AGG(DISTINCT ca_city) AS unique_cities,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip
    FROM customer_address
    GROUP BY ca_state
),

CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd_purchase_estimate) AS min_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM customer_demographics
    GROUP BY cd_gender
),

SalesSummary AS (
    SELECT 
        'web' AS sale_type,
        SUM(ws_sales_price) AS total_sales_price,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY sale_type
    UNION ALL
    SELECT 
        'store' AS sale_type,
        SUM(ss_sales_price) AS total_sales_price,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS total_orders
    FROM store_sales
    GROUP BY sale_type
)

SELECT 
    asum.ca_state,
    asum.address_count,
    asum.city_with_ville_count,
    ARRAY_SIZE(asum.unique_cities) AS unique_city_count,
    cd.cd_gender,
    cd.demographic_count,
    cd.max_purchase_estimate,
    cd.min_purchase_estimate,
    cd.total_dependents,
    ss.sale_type,
    ss.total_sales_price,
    ss.avg_sales_price,
    ss.total_orders
FROM AddressSummary asum
JOIN CustomerDemographics cd ON cd.demographic_count > 100
JOIN SalesSummary ss ON ss.total_sales_price > 10000
ORDER BY asum.ca_state, cd.cd_gender, ss.total_sales_price DESC;
