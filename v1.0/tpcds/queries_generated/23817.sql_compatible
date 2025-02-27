
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank,
        CASE 
            WHEN SUM(ws_net_profit) IS NULL THEN 'Unknown Profit'
            WHEN SUM(ws_net_profit) = 0 THEN 'Break Even'
            ELSE 'Profit'
        END AS profit_status
    FROM web_sales
    GROUP BY ws_item_sk
),
HighValueItems AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity,
        rs.total_profit,
        rs.profit_status
    FROM RecursiveSales rs
    WHERE rs.profit_rank <= 10
),
LowInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) < 5
),
FinalSelection AS (
    SELECT 
        hvi.ws_item_sk,
        hvi.total_quantity,
        hvi.total_profit,
        hvi.profit_status,
        li.total_inventory
    FROM HighValueItems hvi
    LEFT JOIN LowInventory li ON hvi.ws_item_sk = li.inv_item_sk
)
SELECT 
    fs.ws_item_sk,
    COALESCE(fs.total_quantity, 0) AS quantity_sold,
    COALESCE(fs.total_profit, 0.00) AS total_profit_amount,
    fs.profit_status,
    CASE 
        WHEN fs.total_inventory IS NULL THEN 'Out of Stock'
        WHEN fs.total_inventory = 0 THEN 'Sold Out'
        ELSE CONCAT('Available: ', fs.total_inventory)
    END AS inventory_status
FROM FinalSelection fs
WHERE (fs.profit_status = 'Profit' AND fs.total_inventory IS NOT NULL)
   OR (fs.profit_status = 'Unknown Profit' AND fs.total_inventory IS NULL)
ORDER BY fs.total_profit DESC, fs.quantity_sold ASC;
