
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451550
),
ReturnedSales AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_ticket_number) AS num_returns
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
AggregatedData AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM
        catalog_sales cs
    LEFT JOIN
        ReturnedSales rs ON cs.cs_item_sk = rs.sr_item_sk
    WHERE
        rs.num_returns IS NULL OR rs.num_returns < 5
    GROUP BY
        cs.cs_item_sk
),
FinalOutput AS (
    SELECT
        a.cs_item_sk,
        a.total_profit,
        a.order_count,
        a.max_sales_price,
        r.ws_order_number
    FROM
        AggregatedData a
    LEFT JOIN
        RankedSales r ON a.cs_item_sk = r.ws_item_sk AND r.price_rank = 1
    WHERE
        COALESCE(a.total_profit, 0) > (SELECT AVG(total_profit) FROM AggregatedData)
)
SELECT
    fo.cs_item_sk,
    fo.total_profit,
    fo.order_count,
    fo.max_sales_price,
    COALESCE(fo.ws_order_number, 'No Sale') AS ws_order_number
FROM
    FinalOutput fo
WHERE
    (fo.total_profit > 1000 OR fo.order_count > 10)
    AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_state IN ('NY', 'CA') 
          AND COALESCE(ca.ca_zip, '00000') != '00000'
    )
ORDER BY
    fo.total_profit DESC, 
    fo.order_count ASC
LIMIT 50;
