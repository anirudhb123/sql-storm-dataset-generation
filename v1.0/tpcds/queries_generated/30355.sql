
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS Lev
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity + s.ws_quantity,
        ws_sales_price,
        ws_net_profit + s.ws_net_profit,
        Lev + 1
    FROM web_sales s
    JOIN SalesCTE c ON s.ws_item_sk = c.ws_item_sk
    WHERE c.Lev < 5
),
AggregatedSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(s.ws_net_profit) DESC) AS profit_rank
    FROM SalesCTE s
    JOIN item ON s.ws_item_sk = item.i_item_sk
    GROUP BY item.i_item_id, item.i_item_desc
),
TopItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        total_quantity,
        total_profit
    FROM AggregatedSales
    WHERE profit_rank <= 10
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    ci.total_quantity,
    ci.total_profit,
    COALESCE((SELECT SUM(wr_return_quantity) FROM web_returns wr WHERE wr.wr_item_sk = ci.i_item_id), 0) AS total_web_returns,
    COALESCE((SELECT SUM(sr_return_quantity) FROM store_returns sr WHERE sr.sr_item_sk = ci.i_item_id), 0) AS total_store_returns,
    (ci.total_profit - COALESCE((SELECT SUM(wr_return_amt) FROM web_returns wr WHERE wr.wr_item_sk = ci.i_item_id), 0) 
     - COALESCE((SELECT SUM(sr_return_amt) FROM store_returns sr WHERE sr.sr_item_sk = ci.i_item_id), 0)) AS net_profit_after_returns
FROM TopItems ci
LEFT JOIN (SELECT w_item_sk, COUNT(*) AS returns_count
            FROM web_returns
            GROUP BY w_item_sk) wr ON ci.i_item_id = wr.w_item_sk
LEFT JOIN (SELECT s_item_sk, COUNT(*) AS returns_count
            FROM store_returns 
            GROUP BY s_item_sk) sr ON ci.i_item_id = sr.s_item_sk
WHERE ci.total_profit > 1000
ORDER BY ci.total_profit DESC;
