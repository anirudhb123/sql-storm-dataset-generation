
WITH SalesData AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        AVG(ws.net_profit) AS avg_profit
    FROM web_sales ws
    WHERE ws.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws.sold_date_sk, ws.item_sk
),
InventoryData AS (
    SELECT 
        inv.inv_date_sk,
        inv.inv_item_sk,
        MIN(inv.inv_quantity_on_hand) AS min_stock,
        MAX(inv.inv_quantity_on_hand) AS max_stock
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
),
ItemDetails AS (
    SELECT 
        i.item_sk,
        i.item_desc,
        CONCAT(i.brand, ' - ', i.product_name) AS full_description
    FROM item i
),
CombinedData AS (
    SELECT 
        sd.sold_date_sk,
        id.item_sk,
        id.full_description,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.avg_profit, 0) AS avg_profit,
        COALESCE(id.min_stock, 0) AS min_stock,
        COALESCE(id.max_stock, 0) AS max_stock
    FROM SalesData sd
    FULL OUTER JOIN InventoryData id ON sd.item_sk = id.inv_item_sk
    LEFT JOIN ItemDetails iid ON id.inv_item_sk = iid.item_sk
)
SELECT 
    cd.sold_date_sk,
    cd.item_sk,
    cd.full_description,
    cd.total_quantity,
    cd.total_sales,
    cd.avg_profit,
    cd.min_stock,
    cd.max_stock,
    (cd.total_sales - (cd.total_quantity * (SELECT AVG(i_current_price) FROM item WHERE i_item_sk = cd.item_sk))) AS profit_adjusted_sales
FROM CombinedData cd
WHERE cd.total_sales > 1000
ORDER BY cd.sold_date_sk DESC, cd.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
