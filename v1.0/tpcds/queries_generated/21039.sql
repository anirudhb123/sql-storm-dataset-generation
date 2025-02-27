
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT
        item.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COALESCE(AVG(ws.ws_sales_price), 0) AS average_sales_price
    FROM
        item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY item.i_item_id
),
HighProfitItems AS (
    SELECT
        ss.i_item_id,
        ss.total_quantity,
        ss.total_profit,
        ss.average_sales_price
    FROM
        SalesSummary ss
    WHERE
        ss.total_profit > (SELECT AVG(total_profit) FROM SalesSummary)
),
DateRange AS (
    SELECT
        d.d_date_id,
        d.d_date,
        d.d_month_seq
    FROM
        date_dim d
    WHERE
        d.d_date BETWEEN '2022-01-01' AND '2023-12-31'
),
ShipmentModes AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier
    FROM
        ship_mode sm
    WHERE
        sm.sm_type LIKE '%Ground%'
)
SELECT
    hpi.i_item_id,
    dp.d_date,
    sm.sm_carrier,
    hpi.total_quantity,
    hpi.total_profit,
    hpi.average_sales_price
FROM
    HighProfitItems hpi
CROSS JOIN DateRange dp
LEFT JOIN ShipmentModes sm ON dp.d_date_id = (SELECT MIN(date.d_date_id) FROM date_dim date WHERE date.d_month_seq = dp.d_month_seq)
WHERE
    EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE hpi.i_item_id = ss.ss_item_sk
        AND ss.ss_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_week_seq < 10
        )
    )
ORDER BY
    hpi.total_profit DESC, dp.d_date DESC;
