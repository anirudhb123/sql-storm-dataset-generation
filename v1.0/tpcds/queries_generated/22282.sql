
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price)
                                  FROM web_sales ws2
                                  WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
HighValueReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS total_returns
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
    HAVING
        SUM(wr.wr_return_amt) > 100
),
InventoryLevels AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
    HAVING
        SUM(inv.inv_quantity_on_hand) > 50
)
SELECT
    i.i_item_id,
    COALESCE(rk.sales_rank, 0) AS rank,
    COALESCE(rv.total_return_amt, 0) AS total_return_amt,
    COALESCE(iv.total_inventory, 0) AS total_inventory,
    CASE
        WHEN COALESCE(rv.total_return_amt, 0) > 500 THEN 'High Return'
        WHEN COALESCE(iv.total_inventory, 0) < 20 THEN 'Low Stock'
        ELSE 'Normal'
    END AS status
FROM
    item i
LEFT JOIN RankedSales rk ON i.i_item_sk = rk.ws_item_sk AND rk.sales_rank <= 10
LEFT JOIN HighValueReturns rv ON i.i_item_sk = rv.wr_item_sk
LEFT JOIN InventoryLevels iv ON i.i_item_sk = iv.inv_item_sk
WHERE
    i.i_current_price IS NOT NULL
    AND (i.i_current_price - COALESCE(rv.total_return_amt, 0) / NULLIF(COALESCE(rv.total_returns, 1), 0)) > 0
    OR COALESCE(rv.total_return_amt, 0) IS NULL)
ORDER BY
    COALESCE(rv.total_return_amt, 0) DESC,
    i.i_item_id
LIMIT 100;
