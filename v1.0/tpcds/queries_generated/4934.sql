
WITH RankedSales AS (
    SELECT 
        ws.item_sk,
        SUM(ws.net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.item_sk
), ItemReturns AS (
    SELECT 
        wr.item_sk,
        SUM(wr.return_quantity) AS total_return_quantity,
        SUM(wr.return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.item_sk = ws.item_sk AND wr.order_number = ws.order_number
    GROUP BY 
        wr.item_sk
), ItemDetails AS (
    SELECT 
        i.item_sk,
        i.item_desc,
        COALESCE(rs.total_net_profit, 0) AS total_net_profit,
        COALESCE(ir.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ir.total_return_amount, 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.item_sk = rs.item_sk
    LEFT JOIN 
        ItemReturns ir ON i.item_sk = ir.item_sk
)
SELECT 
    id.item_sk,
    id.item_desc,
    id.total_net_profit,
    id.total_return_quantity,
    id.total_return_amount,
    (id.total_net_profit - id.total_return_amount) AS net_final_profit,
    CASE 
        WHEN id.total_return_quantity = 0 THEN 'No Returns'
        WHEN id.total_net_profit < 0 THEN 'Net Loss'
        ELSE 'Profitable'
    END AS profit_status
FROM 
    ItemDetails id
WHERE 
    id.total_net_profit > 1000
ORDER BY 
    id.total_net_profit DESC
LIMIT 10;
