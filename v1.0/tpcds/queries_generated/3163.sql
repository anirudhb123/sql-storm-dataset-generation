
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND dd.d_dow IN (1, 2, 3, 4, 5) -- Weekdays only
),
CustomerReturns AS (
    SELECT
        wr.wr_returned_date_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM
        web_returns wr
    JOIN
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        wr.wr_returned_date_sk
),
SalesWithReturns AS (
    SELECT
        r.web_site_sk,
        r.ws_sold_date_sk,
        r.ws_item_sk,
        r.ws_quantity,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0) AS total_return_amt,
        r.ws_net_profit AS net_profit
    FROM
        RankedSales r
    LEFT JOIN
        CustomerReturns c ON r.ws_sold_date_sk = c.wr_returned_date_sk
)
SELECT
    s.web_site_sk,
    SUM(s.ws_quantity) AS total_quantity,
    SUM(s.net_profit) AS total_net_profit,
    SUM(s.total_returns) AS total_returns,
    SUM(s.total_return_amt) AS total_return_amt,
    ROUND(SUM(s.net_profit) / NULLIF(SUM(s.ws_quantity), 0), 2) AS average_profit_per_item
FROM
    SalesWithReturns s
WHERE
    s.sales_rank <= 10
GROUP BY
    s.web_site_sk
ORDER BY
    total_net_profit DESC;
