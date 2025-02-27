
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        COALESCE(ws.ws_ship_date_sk, ss.ss_sold_date_sk) AS ship_date,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    LEFT JOIN
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnData AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_returned_date_sk, cr.cr_item_sk
),
CombinedSales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.ship_date,
        sd.ws_item_sk,
        sd.total_web_sales,
        sd.total_web_profit,
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        (sd.total_web_profit - COALESCE(rd.total_return_amount, 0)) AS net_profit_after_returns
    FROM
        SalesData sd
    LEFT JOIN
        ReturnData rd ON sd.ship_date = rd.cr_returned_date_sk AND sd.ws_item_sk = rd.cr_item_sk
)
SELECT
    cb.*
FROM
    CombinedSales cb
WHERE
    cb.net_profit_after_returns > 0
    AND cb.total_web_sales IS NOT NULL
    AND cb.total_returned_quantity < 10
ORDER BY
    cb.ws_sold_date_sk DESC, cb.net_profit_after_returns DESC
LIMIT 100
UNION ALL
SELECT 
    date_dim.d_date_sk AS ws_sold_date_sk,
    NULL AS ship_date,
    NULL AS ws_item_sk,
    SUM(ws_ext_sales_price) AS total_web_sales,
    SUM(ws_net_profit) AS total_web_profit,
    0 AS total_returned_quantity,
    0 AS total_return_amount,
    SUM(ws_net_profit) AS net_profit_after_returns
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023
GROUP BY
    d_date_sk
HAVING
    SUM(ws_net_profit) > 10000
ORDER BY 
    total_web_profit DESC;
