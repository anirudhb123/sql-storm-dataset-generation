
WITH RecursiveSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
RankedItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_revenue, 0) AS total_revenue,
        CASE
            WHEN rs.item_rank IS NULL THEN 'Not Ranked'
            ELSE 'Ranked'
        END AS rank_status
    FROM item i
    LEFT JOIN RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
),
SalesAnalysis AS (
    SELECT
        r.i_item_id,
        r.i_item_desc,
        r.total_quantity,
        r.total_revenue,
        r.rank_status,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_web_customers
    FROM RankedItems r
    LEFT JOIN store_sales ss ON r.i_item_sk = ss.ss_item_sk
    GROUP BY r.i_item_id, r.i_item_desc, r.total_quantity, r.total_revenue, r.rank_status
),
FinalReport AS (
    SELECT 
        fa.i_item_id,
        fa.i_item_desc,
        fa.total_quantity,
        fa.total_revenue,
        fa.rank_status,
        fa.total_store_sales,
        fa.unique_web_customers,
        CASE
            WHEN fa.total_revenue > 1000 THEN 'High Revenue'
            WHEN fa.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Revenue'
            ELSE 'Low Revenue'
        END AS revenue_band,
        CASE 
            WHEN fa.total_quantity > 100 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS volume_band
    FROM SalesAnalysis fa
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.total_quantity,
    f.total_revenue,
    f.rank_status,
    f.total_store_sales,
    f.unique_web_customers,
    f.revenue_band,
    f.volume_band
FROM FinalReport f
WHERE f.rank_status = 'Ranked' 
    AND (f.total_store_sales > 0 OR f.unique_web_customers > 0)
ORDER BY f.total_revenue DESC, f.unique_web_customers DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM FinalReport) / 2;

```
