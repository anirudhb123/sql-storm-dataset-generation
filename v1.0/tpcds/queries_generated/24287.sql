
WITH TotalSales AS (
    SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452050 AND 2452370
    GROUP BY ws_item_sk
), 
AverageSales AS (
    SELECT ws_item_sk, AVG(ws_ext_sales_price) OVER (PARTITION BY ws_item_sk) AS avg_sales
    FROM web_sales
), 
PromotionsUsed AS (
    SELECT p.p_promo_id, COUNT(DISTINCT ws_order_number) AS promo_count
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
), 
DetailedReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns,
        (CASE 
            WHEN SUM(sr_return_quantity) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END) AS return_status
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalMetrics AS (
    SELECT ts.ws_item_sk, ts.total_sales, COALESCE(as.avg_sales, 0) AS avg_sales,
           COALESCE(pr.promo_count, 0) AS promo_count, COALESCE(dr.total_returns, 0) AS total_returns,
           dr.return_status
    FROM TotalSales ts
    LEFT JOIN AverageSales as ON ts.ws_item_sk = as.ws_item_sk
    LEFT JOIN PromotionsUsed pr ON ts.ws_item_sk = pr.ws_item_sk
    LEFT JOIN DetailedReturns dr ON ts.ws_item_sk = dr.sr_item_sk
)
SELECT 
    fm.ws_item_sk,
    fm.total_sales,
    fm.avg_sales,
    fm.promo_count,
    fm.total_returns,
    CASE 
        WHEN fm.total_sales IS NULL THEN 'No Sales Data'
        WHEN fm.avg_sales <= 0 THEN 'Below Average Sales'
        WHEN fm.total_returns > 10 THEN 'High Returns'
        ELSE 'Normal'
    END AS sales_status
FROM FinalMetrics fm
WHERE fm.total_sales > (SELECT AVG(total_sales) FROM FinalMetrics) 
    OR fm.total_returns IS NULL 
ORDER BY fm.total_sales DESC
LIMIT 100;
