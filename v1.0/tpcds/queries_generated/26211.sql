
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        COUNT(DISTINCT ca_city) AS unique_cities,
        SUM(LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1) AS word_count_street_name,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        s_store_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    JOIN 
        store ON web_sales.ws_store_sk = store.s_store_sk
    GROUP BY 
        s_store_sk
)
SELECT 
    A.ca_state,
    A.address_count,
    A.unique_cities,
    A.word_count_street_name,
    A.avg_gmt_offset,
    C.cd_gender,
    C.customer_count,
    C.avg_purchase_estimate,
    C.total_dependents,
    S.total_orders,
    S.total_sales,
    S.total_net_profit
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON C.customer_count > 1000
JOIN 
    SalesSummary S ON S.total_sales > 10000
ORDER BY 
    A.address_count DESC, 
    C.customer_count DESC;
