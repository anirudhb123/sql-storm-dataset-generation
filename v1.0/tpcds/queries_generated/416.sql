
WITH RankedSales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_date_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),

TopSales AS (
    SELECT 
        r.ws_ship_date_sk,
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales
    FROM RankedSales r
    WHERE r.rank_sales <= 10
),

CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),

SalesAndReturns AS (
    SELECT 
        t.ws_item_sk,
        t.total_quantity,
        t.total_sales,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_returned_amount, 0) AS total_returned_amount,
        (t.total_sales - COALESCE(c.total_returned_amount, 0)) AS net_sales
    FROM TopSales t
    LEFT JOIN CustomerReturns c ON t.ws_item_sk = c.sr_item_sk
)

SELECT 
    s.ws_item_sk, 
    s.total_quantity,
    s.total_sales, 
    s.total_returns,
    s.total_returned_amount,
    s.net_sales,
    CASE 
        WHEN s.net_sales > 10000 THEN 'High Performer'
        WHEN s.net_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SalesAndReturns s
JOIN date_dim d ON s.ws_ship_date_sk = d.d_date_sk
WHERE d.d_year = 2023 
AND d.d_month_seq BETWEEN 1 AND 3
ORDER BY net_sales DESC;
