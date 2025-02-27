
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (
            SELECT MAX(ws_sold_date_sk)
            FROM web_sales
        )
    UNION ALL
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit * 1.1 AS ws_net_profit,
        level + 1
    FROM
        web_sales ws
    INNER JOIN SalesCTE cte ON ws.ws_item_sk = cte.ws_item_sk
    WHERE
        level < 5
),
InventoryCTE AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SalesSummary AS (
    SELECT 
        cte.ws_item_sk,
        SUM(cte.ws_quantity) AS total_quantity_sold,
        SUM(cte.ws_net_profit) AS total_net_profit,
        COALESCE(inv.total_stock, 0) AS total_stock,
        RANK() OVER (ORDER BY SUM(cte.ws_net_profit) DESC) AS profit_rank
    FROM 
        SalesCTE cte
    LEFT JOIN 
        InventoryCTE inv ON cte.ws_item_sk = inv.inv_item_sk
    GROUP BY 
        cte.ws_item_sk, inv.total_stock
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    ss.total_quantity_sold,
    ss.total_net_profit,
    ss.total_stock,
    ss.profit_rank
FROM 
    SalesSummary ss
JOIN 
    item ON ss.ws_item_sk = item.i_item_sk
WHERE 
    ss.total_stock > 0
    AND ss.profit_rank <= 10
ORDER BY 
    ss.total_net_profit DESC;
