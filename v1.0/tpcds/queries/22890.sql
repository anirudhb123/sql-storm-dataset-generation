
WITH RECURSIVE AddressAnalytics AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        COUNT(c_customer_sk) AS customer_count
    FROM customer_address
    LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state, ca_country
),
DemographicStats AS (
    SELECT 
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
    GROUP BY cd_marital_status
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CombinedSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_store_sales
    FROM store_sales
    GROUP BY ss_item_sk
),
FinalSales AS (
    SELECT 
        A.ca_city,
        A.ca_state,
        A.ca_country,
        COALESCE(S.total_sales, 0) AS web_sales,
        COALESCE(C.total_store_sales, 0) AS store_sales,
        D.avg_purchase_estimate,
        D.demographic_count
    FROM AddressAnalytics A
    LEFT JOIN SalesSummary S ON A.customer_count = S.order_count
    LEFT JOIN CombinedSales C ON S.ws_item_sk = C.ss_item_sk
    LEFT JOIN DemographicStats D ON A.ca_state = D.cd_marital_status
)
SELECT 
    ca_city,
    ca_state,
    ca_country,
    CASE 
        WHEN web_sales > store_sales THEN 'Web Dominates'
        WHEN web_sales < store_sales THEN 'Store Dominates'
        ELSE 'Equal Sales'
    END AS sales_dominance,
    COALESCE(CASE WHEN avg_purchase_estimate IS NULL THEN 'Unknown' ELSE CAST(avg_purchase_estimate AS CHAR) END, 'N/A') AS avg_purchase,
    demographic_count
FROM FinalSales
WHERE demographic_count > (SELECT AVG(demographic_count) FROM DemographicStats)
ORDER BY ca_state, ca_city;
