
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_net_profit,
        1 AS level
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_net_profit,
        cte.level + 1
    FROM web_sales ws
    INNER JOIN SalesCTE cte ON ws.ws_sold_date_sk = cte.ws_sold_date_sk - INTERVAL '1 day'
    WHERE cte.level < 30
), 
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        SUM(sr_return_quantity) AS total_return_quantity, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
SalesAggregated AS (
    SELECT 
        d.d_date_id,
        SUM(s.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT s.ws_order_number) AS total_orders,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amt, 0) AS total_return_amt
    FROM date_dim d
    LEFT JOIN SalesCTE s ON s.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN CustomerReturns r ON r.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date_id
),
RankedSales AS (
    SELECT 
        d.d_date_id, 
        sa.total_net_profit, 
        sa.total_orders,
        sa.total_return_quantity,
        sa.total_return_amt,
        RANK() OVER (ORDER BY sa.total_net_profit DESC) AS profit_rank
    FROM SalesAggregated sa
    JOIN date_dim d ON d.d_date_sk = sa.d_date_id
)
SELECT 
    rs.d_date_id,
    rs.total_net_profit,
    rs.total_orders,
    rs.total_return_quantity,
    rs.total_return_amt,
    CASE 
        WHEN rs.total_net_profit > 10000 THEN 'High Profit'
        WHEN rs.total_net_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM RankedSales rs
WHERE rs.profit_rank <= 10
ORDER BY rs.total_net_profit DESC
