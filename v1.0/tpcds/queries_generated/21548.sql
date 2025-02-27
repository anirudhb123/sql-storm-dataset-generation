
WITH RankedSales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        SUM(ss.ss_sales_price) OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk) AS running_total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rank
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 20001 AND 20030
),
ItemReturns AS (
    SELECT
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amounts
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
SalesWithReturns AS (
    SELECT
        rs.ss_item_sk,
        rs.running_total_sales,
        COALESCE(ir.total_returns, 0) AS total_returns,
        COALESCE(ir.total_return_amounts, 0) AS total_return_amounts,
        CASE 
            WHEN COALESCE(ir.total_returns, 0) > 0 THEN 
                (rs.running_total_sales / NULLIF(ir.total_returns, 0))::decimal(10, 2)
            ELSE NULL 
        END AS sales_per_return
    FROM RankedSales rs
    LEFT JOIN ItemReturns ir ON rs.ss_item_sk = ir.sr_item_sk
),
FinalReport AS (
    SELECT
        s.item_id,
        s.running_total_sales,
        s.total_returns,
        s.total_return_amounts,
        s.sales_per_return,
        CASE 
            WHEN s.sales_per_return IS NULL THEN 'No Returns'
            WHEN s.sales_per_return < 10 THEN 'Low Return Rate'
            ELSE 'Regular Return Rate' 
        END AS return_rate_category
    FROM SalesWithReturns s
    JOIN item i ON s.ss_item_sk = i.i_item_sk
    WHERE s.rank = 1
)
SELECT
    fr.item_id,
    fr.running_total_sales,
    fr.total_returns,
    fr.total_return_amounts,
    fr.sales_per_return,
    fr.return_rate_category,
    d.d_day_name,
    sm.sm_type,
    COALESCE((SELECT
                SUM(ws.ws_net_profit)
                FROM web_sales ws
                WHERE ws.ws_ship_date_sk = fr.running_total_sales), 0) AS web_sales_profit
FROM FinalReport fr
LEFT JOIN date_dim d ON d.d_date_sk BETWEEN 20001 AND 20030
LEFT JOIN ship_mode sm ON fr.total_returns > 0 AND sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk FROM ship_mode ORDER BY RANDOM() LIMIT 1)
ORDER BY fr.running_total_sales DESC, fr.total_returns ASC;
