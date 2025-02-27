
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_item_sk, ws.ws_ship_date_sk
),
TopSellingItems AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesCTE
    WHERE
        sales_rank <= 100
),
InventoryStatus AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
),
SalesReturn AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_qty) AS total_returns,
        SUM(sr.sr_return_amt) AS return_amount
    FROM
        store_returns sr
    GROUP BY
        sr.sr_item_sk
)
SELECT
    tsi.ws_item_sk,
    tsi.total_quantity,
    tsi.total_sales,
    COALESCE(iv.total_on_hand, 0) AS total_inventory,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.return_amount, 0) AS total_return_value,
    tsi.total_sales - COALESCE(sr.return_amount, 0) AS net_sales
FROM
    TopSellingItems tsi
LEFT JOIN
    InventoryStatus iv ON tsi.ws_item_sk = iv.inv_item_sk
LEFT JOIN
    SalesReturn sr ON tsi.ws_item_sk = sr.sr_item_sk
WHERE
    tsi.rank <= 50 AND tsi.ws_ship_date_sk IS NOT NULL
ORDER BY
    net_sales DESC;
