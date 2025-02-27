
WITH RECURSIVE SalesCTE AS (
    SELECT
        cs_order_number,
        cs_sales_price,
        cs_sold_date_sk,
        cs_ship_mode_sk,
        1 AS level
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN 20200101 AND 20201231
    UNION ALL
    SELECT
        ss.ticket_number AS cs_order_number,
        ss.sales_price AS cs_sales_price,
        ss.sold_date_sk AS cs_sold_date_sk,
        ss.ship_mode_sk AS cs_ship_mode_sk,
        level + 1
    FROM
        store_sales ss
    INNER JOIN SalesCTE ON ss.order_number = SalesCTE.cs_order_number
    WHERE
        ss.sold_date_sk BETWEEN 20200101 AND 20201231 AND level < 5
),
AggregatedSales AS (
    SELECT
        sm.sm_ship_mode_id,
        SUM(cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        AVG(cs_sales_price) AS avg_sales_price
    FROM
        SalesCTE s
    LEFT JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_id
)
SELECT 
    COALESCE(agg.sm_ship_mode_id, 'ALL') AS ship_mode,
    COALESCE(agg.total_sales, 0) AS total_sales_value,
    COALESCE(agg.total_orders, 0) AS total_order_count,
    COALESCE(agg.avg_sales_price, 0) AS average_sales_value,
    CASE 
        WHEN agg.total_sales IS NULL THEN 'NO SALES'
        WHEN agg.total_sales > 1000000 THEN 'HIGH'
        WHEN agg.total_sales BETWEEN 500000 AND 1000000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_performance
FROM
    AggregatedSales agg
FULL OUTER JOIN ship_mode sm ON agg.sm_ship_mode_id = sm.sm_ship_mode_id
WHERE
    (sm.sm_type IS NULL OR sm.sm_type LIKE '%Express%')
ORDER BY
    total_sales_value DESC;
