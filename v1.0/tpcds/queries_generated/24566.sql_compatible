
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt) AS average_return_amt
    FROM store_returns
    WHERE sr_return_time_sk IN (
        SELECT t_time_sk 
        FROM time_dim 
        WHERE t_hour > 5 
          AND t_hour < 18 
          AND t_day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday')
    )
    GROUP BY sr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_ext_sales_price,
        ar.total_returns,
        ar.average_return_amt
    FROM RankedSales rs
    LEFT JOIN AggregateReturns ar ON rs.ws_item_sk = ar.sr_item_sk
    WHERE rs.rank = 1
)
SELECT 
    swr.ws_item_sk,
    COALESCE(swr.ws_quantity, 0) AS sold_quantity,
    COALESCE(swr.ws_ext_sales_price, 0) AS total_sales,
    COALESCE(swr.total_returns, 0) AS total_returns,
    COALESCE(swr.average_return_amt, 0) AS average_return_amount,
    CASE 
        WHEN swr.total_returns > 0 THEN 
            (swr.total_returns * 100.0) / NULLIF(swr.sold_quantity, 0) 
        ELSE 0 
    END AS return_rate
FROM SalesWithReturns swr
WHERE swr.ws_ext_sales_price > (
    SELECT AVG(ws_ext_sales_price) 
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN (
        SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022
    ) AND (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
    )
)
ORDER BY return_rate DESC
LIMIT 10;
