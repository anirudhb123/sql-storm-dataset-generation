
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, 1 AS depth
    FROM item
    WHERE i_item_sk IS NOT NULL

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, CONCAT(ih.i_item_desc, ' -> ', i.i_item_desc), ih.depth + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.brand_id = ih.i_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
ReturnData AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
FinalResults AS (
    SELECT 
        ih.i_item_id,
        ih.i_item_desc,
        sd.ws_order_number,
        sd.ws_quantity,
        sd.ws_ext_sales_price,
        sd.ws_net_profit,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount
    FROM ItemHierarchy ih
    JOIN SalesData sd ON ih.i_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnData rd ON ih.i_item_sk = rd.cr_item_sk
    WHERE sd.rn <= 5
)
SELECT 
    i_item_id,
    i_item_desc,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_ext_sales_price) AS total_sales_amount,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(total_returned) AS aggregated_returns,
    SUM(total_return_amount) AS aggregated_return_amount
FROM FinalResults
GROUP BY i_item_id, i_item_desc
ORDER BY total_net_profit DESC
LIMIT 20;
