
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 
        AND d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023 AND d_dow IN (1, 3))
    )
    GROUP BY ws_item_sk
),
CustomerDemographic AS (
    SELECT 
        cd_demo_sk,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        MAX(cd_dep_count) AS max_dep_count,
        MIN(cd_credit_rating) AS min_credit_rating,
        COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_count
    FROM customer_demographics
    GROUP BY cd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        r.total_sales,
        cd.max_purchase_estimate,
        cd.max_dep_count,
        cd.min_credit_rating,
        cd.female_count
    FROM customer c
    LEFT JOIN RankedSales r ON c.c_customer_sk = r.ws_item_sk
    LEFT JOIN CustomerDemographic cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    s.s_store_name,
    SUM(COALESCE(swd.total_sales, 0)) AS total_sales,
    AVG(COALESCE(swd.max_purchase_estimate, 0)) AS avg_max_purchase_estimate,
    COUNT(DISTINCT swd.c_customer_sk) AS unique_customers,
    SUM(CASE WHEN swd.female_count > 0 THEN 1 ELSE 0 END) AS female_customers
FROM store s
LEFT JOIN SalesWithDemographics swd ON s.s_store_sk = swd.c_customer_sk % 100  -- Bizarre join condition
GROUP BY s.s_store_name
HAVING SUM(COALESCE(swd.total_sales, 0)) > 1000
ORDER BY total_sales DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM store) / 20
UNION ALL
SELECT 
    'N/A' AS store_name,
    0 AS total_sales,
    NULL AS avg_max_purchase_estimate,
    COUNT(*) AS unique_customers,
    NULL AS female_customers
FROM customer
WHERE c_birth_year IS NULL  -- Edge case for NULL logic
ORDER BY total_sales DESC;
