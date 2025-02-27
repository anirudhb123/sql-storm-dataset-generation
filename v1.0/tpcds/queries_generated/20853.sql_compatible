
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL AND ws.ws_quantity > 0
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
CombinedSales AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_sales_quantity,
        SUM(s.ss_ext_sales_price) AS total_sales_amount,
        cs.total_returned,
        cs.return_count
    FROM store_sales s
    LEFT JOIN CustomerReturns cs ON s.ss_item_sk = cs.wr_item_sk
    GROUP BY s.ss_item_sk, cs.total_returned, cs.return_count
),
SalesMetrics AS (
    SELECT 
        cs.ss_item_sk,
        COALESCE(cs.total_sales_quantity, 0) AS total_sales,
        COALESCE(cs.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(cs.total_returned, 0) AS total_returned,
        COALESCE(cs.return_count, 0) AS return_count,
        CASE 
            WHEN COALESCE(cs.total_sales_quantity, 0) = 0 THEN NULL
            ELSE ROUND(COALESCE(cs.total_returned, 0) / NULLIF(COALESCE(cs.total_sales_quantity, 0), 0)::DECIMAL * 100, 2)
        END AS return_rate
    FROM CombinedSales cs
),
RecentSales AS (
    SELECT 
        ss.ss_item_sk,
        DENSE_RANK() OVER (ORDER BY MAX(ss.ss_sold_date_sk) DESC) AS recent_rank
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
)
SELECT 
    sm.ss_item_sk,
    sm.total_sales,
    sm.total_sales_amount,
    sm.total_returned,
    sm.return_count,
    sm.return_rate,
    rs.recent_rank
FROM SalesMetrics sm
JOIN RecentSales rs ON sm.ss_item_sk = rs.ss_item_sk
WHERE (sm.return_rate IS NULL OR sm.return_rate > 10) 
   OR (sm.total_sales_amount >= 1000 AND rs.recent_rank <= 5)
ORDER BY sm.total_sales_amount DESC, rs.recent_rank ASC;
