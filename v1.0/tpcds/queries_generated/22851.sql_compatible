
WITH CustomerDemographicSummary AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(c.c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd_purchase_estimate >= (
        SELECT AVG(cd_purchase_estimate)
        FROM customer_demographics
    )
    GROUP BY cd_gender, cd_marital_status
),
ItemSales AS (
    SELECT
        i.i_item_sk,
        SUM(CASE 
            WHEN ws_item_sk IS NOT NULL THEN ws_quantity 
            ELSE 0 
        END) AS total_web_sales,
        SUM(CASE 
            WHEN cs_item_sk IS NOT NULL THEN cs_quantity 
            ELSE 0 
        END) AS total_catalog_sales,
        SUM(CASE 
            WHEN ss_item_sk IS NOT NULL THEN ss_quantity 
            ELSE 0 
        END) AS total_store_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk
),
SalesAnalysis AS (
    SELECT
        cds.cd_gender,
        cds.cd_marital_status,
        SUM(is.total_web_sales + is.total_catalog_sales + is.total_store_sales) AS grand_total_sales,
        RANK() OVER (PARTITION BY cds.cd_gender ORDER BY SUM(is.total_web_sales + is.total_catalog_sales + is.total_store_sales) DESC) AS sales_rank
    FROM CustomerDemographicSummary cds
    JOIN ItemSales is ON cds.total_customers > 0 AND is.total_web_sales > 0
    GROUP BY cds.cd_gender, cds.cd_marital_status
)
SELECT
    sales_gender,
    sales_marital_status,
    grand_total_sales,
    CASE 
        WHEN sales_rank = 1 THEN 'Top Performer'
        WHEN sales_rank > 1 AND sales_rank <= 3 THEN 'High Performer'
        ELSE 'Other'
    END AS performance_category
FROM (
    SELECT 
        cd_gender AS sales_gender,
        cd_marital_status AS sales_marital_status,
        grand_total_sales,
        sales_rank
    FROM SalesAnalysis 
) AS RankedSales
WHERE grand_total_sales > (SELECT AVG(grand_total_sales) FROM SalesAnalysis)
ORDER BY sales_gender, grand_total_sales DESC;
