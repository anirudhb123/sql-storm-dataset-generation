
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(ca_address_id) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        ARRAY_AGG(ca_city) AS cities_in_state
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
GenderDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        'web' AS sales_channel,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'catalog' AS sales_channel,
        SUM(cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales
    UNION ALL
    SELECT 
        'store' AS sales_channel,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_orders
    FROM 
        store_sales
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.total_addresses,
    a.avg_street_name_length,
    ARRAY_SIZE(a.cities_in_state) AS num_cities,
    g.cd_gender,
    g.customer_count,
    g.avg_purchase_estimate,
    s.sales_channel,
    s.total_sales,
    s.total_orders
FROM 
    AddressSummary a
JOIN 
    GenderDemographics g ON g.customer_count > 100
JOIN 
    SalesSummary s ON s.total_sales > 10000
ORDER BY 
    a.ca_state, g.cd_gender, s.sales_channel;
