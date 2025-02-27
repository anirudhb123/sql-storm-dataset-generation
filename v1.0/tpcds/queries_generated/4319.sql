
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
ItemSales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        sd.order_count
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
),
TopItems AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM ItemSales
),
StorePerformance AS (
    SELECT
        s.s_store_sk,
        SUM(ss.net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ticket_number) AS transaction_count,
        AVG(ss.net_paid_inc_tax) AS avg_sales_price
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY s.s_store_sk
)
SELECT
    ti.i_item_id,
    ti.total_quantity,
    ti.total_sales,
    ti.order_count,
    sp.s_store_sk,
    sp.total_net_profit,
    sp.transaction_count,
    sp.avg_sales_price
FROM TopItems ti
JOIN StorePerformance sp ON ti.total_sales > (SELECT AVG(total_sales) FROM TopItems)
WHERE
    (sp.avg_sales_price IS NOT NULL) AND
    sp.transaction_count > 1
ORDER BY ti.sales_rank, sp.total_net_profit DESC;
