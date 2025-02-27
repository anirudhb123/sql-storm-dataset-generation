
WITH SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, i.i_item_id, i.i_item_desc
),
ReturnsCTE AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_net_loss) AS total_loss
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        s.sold_date,
        s.i_item_id,
        s.i_item_desc,
        s.total_quantity,
        s.total_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_loss, 0) AS total_loss
    FROM 
        SalesCTE s
    LEFT JOIN 
        ReturnsCTE r ON s.i_item_id = r.wr_item_sk
)
SELECT 
    w.warehouse_id,
    SUM(S.total_profit) AS total_profit,
    SUM(S.total_returns) AS total_returns,
    SUM(S.total_loss) AS total_loss
FROM 
    SalesWithReturns S
JOIN 
    inventory inv ON S.i_item_id = inv.inv_item_sk
JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    S.total_profit > 0
    AND S.total_returns < 10
GROUP BY 
    w.warehouse_id
HAVING 
    SUM(S.total_profit) > 10000
ORDER BY 
    total_profit DESC
LIMIT 5;
