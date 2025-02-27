
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as sales_rank
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND i.i_current_price > 20.00
),
TotalReturns AS (
    SELECT 
        irc.ws_item_sk,
        SUM(ircr.ws_return_quantity) AS total_return_quantity,
        SUM(ircr.ws_return_amt_inc_tax) AS total_return_amount
    FROM web_returns ircr
    JOIN RankedSales irc ON irc.ws_item_sk = ircr.wr_item_sk
    GROUP BY irc.ws_item_sk
),
BestSellingItems AS (
    SELECT 
        i.i_item_id,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.sales_rank <= 10
    GROUP BY i.i_item_id
)
SELECT 
    bsi.i_item_id,
    bsi.total_sales,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    (bsi.total_sales - COALESCE(tr.total_return_amount, 0)) AS net_sales
FROM BestSellingItems bsi
LEFT JOIN TotalReturns tr ON bsi.i_item_id = tr.ws_item_sk
ORDER BY net_sales DESC;
