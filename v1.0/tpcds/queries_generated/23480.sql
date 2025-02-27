
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2022 AND d.d_weekend = 'Y'
        )
),
ReturnsSummary AS (
    SELECT
        item_sk,
        SUM(return_quantity) AS total_returns,
        AVG(return_amt_inc_tax) AS avg_return_amt
    FROM (
        SELECT cr.cr_item_sk AS item_sk, cr.cr_return_quantity AS return_quantity, cr.cr_return_amt_inc_tax
        FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_item_sk AS item_sk, wr.wr_return_quantity, wr.wr_return_amt_inc_tax
        FROM web_returns wr
    ) AS CombinedReturns
    GROUP BY item_sk
),
SalesAndReturns AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.ws_sales_price * rs.ws_quantity AS total_sales,
        COALESCE(rs2.total_returns, 0) AS total_returns,
        COALESCE(rs2.avg_return_amt, 0) AS avg_return_amt
    FROM 
        RankedSales rs
    LEFT JOIN ReturnsSummary rs2 ON rs.ws_item_sk = rs2.item_sk
)
SELECT 
    sar.ws_order_number,
    sar.ws_item_sk,
    sar.total_sales,
    sar.total_returns,
    sar.avg_return_amt,
    sar.total_sales - sar.total_returns * (CASE WHEN sar.avg_return_amt > 0 THEN 1 ELSE 0 END) AS net_profit_adjusted
FROM 
    SalesAndReturns sar
WHERE 
    sar.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item i
        WHERE i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_rec_start_date < '2023-01-01')
    )
ORDER BY 
    net_profit_adjusted DESC
FETCH FIRST 10 ROWS ONLY;
