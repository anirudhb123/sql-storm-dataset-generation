
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS ranking
    FROM SalesData
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    tsi.total_quantity, 
    tsi.total_sales
FROM TopSellingItems tsi
JOIN item i ON tsi.ws_item_sk = i.i_item_sk
WHERE tsi.ranking <= 10
ORDER BY tsi.total_sales DESC;

WITH ReturnData AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns, 
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    rd.total_returns, 
    rd.total_return_amount, 
    id.quantity_on_hand
FROM ReturnData rd
JOIN InventoryData id ON rd.sr_item_sk = id.inv_item_sk
JOIN item i ON rd.sr_item_sk = i.i_item_sk
WHERE rd.total_returns > 0 
ORDER BY rd.total_return_amount DESC;
