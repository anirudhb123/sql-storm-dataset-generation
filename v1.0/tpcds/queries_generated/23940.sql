
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk = (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date = CURRENT_DATE
    )
),
RevenueAnalysis AS (
    SELECT 
        css.cs_item_sk,
        SUM(css.cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_profit,
        CASE 
            WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No profitable web sales'
            WHEN SUM(ws.ws_net_profit) = 0 THEN 'Web sold item not profitable'
            ELSE 'Profitable web sales'
        END AS profit_status
    FROM catalog_sales css
    LEFT JOIN web_sales ws ON css.cs_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON css.cs_item_sk = ss.ss_item_sk
    GROUP BY css.cs_item_sk
),
FinalReport AS (
    SELECT 
        it.i_item_id,
        it.i_item_desc,
        COALESCE(ra.total_catalog_sales, 0) AS total_catalog_sales,
        ra.total_web_profit,
        ra.total_store_profit,
        ra.profit_status,
        COUNT(DISTINCT ws.ws_order_number) AS count_of_web_sales
    FROM item it
    LEFT JOIN RevenueAnalysis ra ON it.i_item_sk = ra.cs_item_sk
    LEFT JOIN web_sales ws ON it.i_item_sk = ws.ws_item_sk AND ws.ws_order_number IS NOT NULL
    GROUP BY it.i_item_id, it.i_item_desc, ra.total_catalog_sales, ra.total_web_profit, ra.total_store_profit, ra.profit_status
)
SELECT 
    fr.i_item_id,
    fr.i_item_desc,
    fr.total_catalog_sales,
    fr.total_web_profit,
    fr.total_store_profit,
    fr.profit_status,
    fr.count_of_web_sales
FROM FinalReport fr
WHERE fr.total_catalog_sales > (
    SELECT AVG(total_catalog_sales) 
    FROM FinalReport
) AND fr.total_web_profit > 0
UNION
SELECT 
    'Total' AS i_item_id,
    NULL AS i_item_desc,
    SUM(total_catalog_sales) AS total_catalog_sales,
    SUM(total_web_profit) AS total_web_profit,
    SUM(total_store_profit) AS total_store_profit,
    NULL AS profit_status,
    NULL AS count_of_web_sales
FROM FinalReport
HAVING SUM(total_catalog_sales) IS NOT NULL
ORDER BY total_web_profit DESC, total_catalog_sales ASC
OFFSET 5 ROWS;
