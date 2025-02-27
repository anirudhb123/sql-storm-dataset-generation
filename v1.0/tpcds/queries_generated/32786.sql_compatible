
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_brand, i_current_price, 1 AS level
    FROM item
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_brand, i.i_current_price, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_manager_id = ih.i_item_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_sales_price) AS max_sales_price,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    INNER JOIN ItemHierarchy ih ON ws.ws_item_sk = ih.i_item_sk
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT
        COALESCE(sr.sr_item_sk, cr.cr_item_sk, wr.wr_item_sk) AS item_sk,
        SUM(COALESCE(sr.sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_returns
    FROM store_returns sr
    FULL OUTER JOIN catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
    FULL OUTER JOIN web_returns wr ON wr.wr_item_sk = cr.cr_item_sk OR wr.wr_item_sk = sr.sr_item_sk
    GROUP BY COALESCE(sr.sr_item_sk, cr.cr_item_sk, wr.wr_item_sk)
),
FinalReport AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        rd.total_returns,
        sd.max_sales_price,
        sd.avg_net_paid
    FROM SalesData sd
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.item_sk
    WHERE sd.total_quantity > 100
)
SELECT 
    ih.i_item_id,
    ih.i_product_name,
    ih.i_brand,
    fr.total_quantity,
    fr.total_profit,
    fr.total_returns,
    fr.max_sales_price,
    fr.avg_net_paid
FROM FinalReport fr
JOIN ItemHierarchy ih ON fr.ws_item_sk = ih.i_item_sk
WHERE ih.level = 1
ORDER BY fr.total_profit DESC
LIMIT 50;
