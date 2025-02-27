
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
),
AggregatedReturns AS (
    SELECT
        sr_item_sk,
        SUM(CASE WHEN sr_return_quantity < 0 THEN NULL ELSE sr_return_quantity END) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
HighReturnItems AS (
    SELECT
        ar.sr_item_sk,
        ar.total_returned,
        ar.return_count
    FROM
        AggregatedReturns ar
    WHERE
        ar.total_returned IS NOT NULL AND ar.total_returned > 10
),
SalesAndReturns AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_ext_sales_price,
        COALESCE(hr.total_returned, 0) AS total_returned,
        hr.return_count
    FROM
        RankedSales rs
    LEFT JOIN
        HighReturnItems hr ON rs.ws_item_sk = hr.sr_item_sk
    WHERE
        rs.sales_rank = 1
),
FinalReport AS (
    SELECT
        s.ws_item_sk,
        SUM(s.ws_ext_sales_price) AS total_sales,
        SUM(s.total_returned) AS total_returns,
        (SUM(s.ws_ext_sales_price) - SUM(s.total_returned * (SELECT i.i_current_price FROM item i WHERE i.i_item_sk = s.ws_item_sk))) AS net_profit
    FROM
        SalesAndReturns s
    GROUP BY
        s.ws_item_sk
)
SELECT
    fr.ws_item_sk,
    fr.total_sales,
    fr.total_returns,
    fr.net_profit,
    CASE
        WHEN fr.net_profit IS NULL THEN 'Profit Calculation Error'
        WHEN fr.net_profit > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_status
FROM
    FinalReport fr
WHERE
    fr.total_sales > (SELECT AVG(total_sales) FROM FinalReport) -- Filter for above average sales
ORDER BY
    fr.net_profit DESC;
