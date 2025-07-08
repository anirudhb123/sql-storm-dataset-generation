
WITH RECURSIVE TimeSeries AS (
    SELECT
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_week_seq,
        1 AS level
    FROM
        date_dim
    WHERE
        d_date >= DATE '2022-01-01'
    UNION ALL
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        ts.level + 1
    FROM
        date_dim d
    JOIN
        TimeSeries ts ON d.d_date_sk = ts.d_date_sk + 1
    WHERE
        d.d_date <= DATE '2022-12-31' AND ts.level < 30
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        d_year
    FROM
        web_sales
    JOIN
        TimeSeries ON ws_sold_date_sk = d_date_sk
    GROUP BY
        ws_item_sk, d_year
),
StoreData AS (
    SELECT
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales_store,
        COUNT(ss_ticket_number) AS store_order_count,
        d_year
    FROM
        store_sales
    JOIN
        TimeSeries ON ss_sold_date_sk = d_date_sk
    GROUP BY
        ss_item_sk, d_year
)
SELECT
    COALESCE(ws.ws_item_sk, ss.ss_item_sk) AS item_sk,
    COALESCE(ws.total_sales, 0) AS web_sales_total,
    COALESCE(ss.total_sales_store, 0) AS store_sales_total,
    (COALESCE(ws.total_sales, 0) + COALESCE(ss.total_sales_store, 0)) AS combined_sales_total,
    ws.order_count,
    ss.store_order_count
FROM
    SalesData ws
FULL OUTER JOIN
    StoreData ss ON ws.ws_item_sk = ss.ss_item_sk
WHERE 
    (ws.total_sales > 100 OR ss.total_sales_store > 100)
    AND (ws.order_count IS NOT NULL OR ss.store_order_count IS NOT NULL)
ORDER BY
    combined_sales_total DESC
LIMIT 10;
