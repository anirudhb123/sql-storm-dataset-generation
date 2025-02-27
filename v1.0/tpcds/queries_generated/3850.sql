
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
ItemInventory AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_date_sk, inv_item_sk
),
ReturnStats AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt) AS total_return_amt
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(irs.total_quantity, 0) AS total_quantity_on_hand,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amount,
    SUM(r.sales) OVER (PARTITION BY i.i_item_sk ORDER BY r.ws_sold_date_sk) AS cumulative_sales,
    COUNT(DISTINCT r.ws_order_number) AS total_orders,
    MAX(r.rn) AS highest_profit_rank
FROM 
    item i
LEFT JOIN 
    ItemInventory irs ON i.i_item_sk = irs.inv_item_sk
LEFT JOIN 
    RankedSales r ON i.i_item_sk = r.ws_item_sk
LEFT JOIN 
    ReturnStats rs ON i.i_item_sk = rs.cr_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc, irs.total_quantity, rs.total_returns, rs.total_return_amt
HAVING 
    COUNT(DISTINCT r.ws_order_number) > 0 
ORDER BY 
    cumulative_sales DESC, highest_profit_rank
LIMIT 10;
