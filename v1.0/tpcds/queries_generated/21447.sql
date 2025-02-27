
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rnk
    FROM web_sales
    WHERE ws_net_paid IS NOT NULL
),
FilteredReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    WHERE wr_return_amt IS NOT NULL
    GROUP BY wr_item_sk
),
SalesSummary AS (
    SELECT
        ws.item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        COALESCE(fr.total_returned, 0) AS total_returns,
        COUNT(DISTINCT fr.return_count) AS return_count
    FROM web_sales ws
    LEFT JOIN FilteredReturns fr ON ws.ws_item_sk = fr.wr_item_sk
    GROUP BY ws.item_sk
)
SELECT
    ss.item_sk,
    total_quantity_sold,
    total_net_paid,
    total_returns,
    return_count,
    CASE
        WHEN total_quantity_sold = 0 THEN NULL
        ELSE ROUND((total_returns::decimal / total_quantity_sold) * 100, 2)
    END AS return_rate_percentage,
    CASE
        WHEN ss.item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price <= 0) THEN 'Pricing Error'
        ELSE 'Normal Sale'
    END AS sale_status,
    COALESCE((SELECT MAX(rnk) FROM RankedSales r WHERE r.ws_item_sk = ss.item_sk), 0) AS max_rank
FROM SalesSummary ss
JOIN item i ON ss.item_sk = i.i_item_sk
WHERE i.i_item_desc IS NOT NULL
ORDER BY return_rate_percentage DESC NULLS LAST
LIMIT 100;
