
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
TopReturns AS (
    SELECT
        r.*,
        COALESCE((SELECT COUNT(*) FROM store s WHERE s.s_store_sk = sr.store_sk AND s.s_state IN ('NY', 'CA')), 0) AS valid_store_count
    FROM RankedReturns r
    LEFT JOIN store s ON r.sr_store_sk = s.s_store_sk
    WHERE r.return_rank <= 5
),
FilteredSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_creation_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws.web_site_sk, ws.ws_order_number
),
TotalReturns AS (
    SELECT
        SUM(sr_return_quantity) AS total_returned
    FROM TopReturns
    WHERE return_rank = 1
),
AggregatedData AS (
    SELECT
        fs.web_site_sk,
        fs.total_quantity,
        fs.avg_net_profit,
        tr.total_returned,
        CASE 
            WHEN fs.total_quantity > 100 THEN 'High Volume'
            WHEN fs.total_quantity BETWEEN 1 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS sales_volume_category,
        CASE 
            WHEN tr.total_returned > 50 THEN 'High Returns'
            ELSE 'Manageable Returns'
        END AS return_category
    FROM FilteredSales fs
    JOIN TotalReturns tr ON 1 = 1
)
SELECT 
    ad.web_site_sk,
    ad.sales_volume_category,
    ad.return_category,
    COUNT(DISTINCT ad.web_site_sk) OVER (PARTITION BY ad.sales_volume_category) AS site_count,
    MAX(ad.avg_net_profit) OVER (PARTITION BY ad.return_category) AS max_avg_net_profit
FROM AggregatedData ad
WHERE ad.total_quantity IS NOT NULL AND ad.total_returned IS NOT NULL
ORDER BY ad.web_site_sk, ad.sales_volume_category DESC;
