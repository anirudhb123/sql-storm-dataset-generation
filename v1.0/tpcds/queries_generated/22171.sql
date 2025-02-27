
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(NULLIF(ws.ws_sales_price, 0), ws.ws_ext_sales_price) AS effective_price,
        d.d_year,
        d.d_month_seq
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
CustomerReturns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt) AS total_return_amt
    FROM catalog_returns
    GROUP BY cr_item_sk
    HAVING SUM(cr_return_quantity) > 0
),
CustomerWithReturns AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.sales_rank,
        r.effective_price,
        cr.total_returns,
        cr.total_return_amt
    FROM RankedSales r
    LEFT JOIN CustomerReturns cr ON r.ws_item_sk = cr.cr_item_sk
    WHERE r.sales_rank = 1 AND r.effective_price IS NOT NULL
),
FinalMetrics AS (
    SELECT
        cwr.ws_item_sk,
        cwr.ws_order_number,
        cwr.effective_price,
        COALESCE(cwr.total_returns, 0) AS total_returns,
        COALESCE(cwr.total_return_amt, 0.00) AS total_return_amt,
        CASE 
            WHEN cwr.total_returns > 0 THEN (cwr.effective_price * cwr.total_returns)
            ELSE 0
        END AS revenue_loss_from_returns
    FROM CustomerWithReturns cwr
)
SELECT
    f.ws_item_sk,
    COUNT(DISTINCT f.ws_order_number) AS order_count,
    SUM(f.effective_price) AS total_sales,
    SUM(f.revenue_loss_from_returns) AS total_loss,
    AVG(f.effective_price) AS average_price,
    MAX(f.total_returns) AS max_returned_items
FROM FinalMetrics f
WHERE f.total_loss IS NOT NULL
GROUP BY f.ws_item_sk
HAVING SUM(f.total_loss) > (SELECT AVG(total_loss) FROM FinalMetrics)
ORDER BY total_sales DESC
LIMIT 10;
