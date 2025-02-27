
WITH Ranked_Sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
),
Return_Summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
Final_Summary AS (
    SELECT 
        cs.cs_item_sk,
        COALESCE(rs.rank, 999) AS sales_rank,
        COALESCE(rs.ws_quantity, 0) AS quantity_sold,
        COALESCE(rs.ws_net_profit, 0) AS net_profit,
        COALESCE(rs.ws_sales_price, 0) AS sales_price,
        COALESCE(rs.ws_net_profit / NULLIF(rs.ws_quantity, 0), 0) AS avg_profit_per_unit,
        COALESCE(rs.ws_quantity, 0) - COALESCE(rs_warnings.total_returns, 0) AS net_quantity
    FROM 
        Ranked_Sales rs
    FULL OUTER JOIN Return_Summary rs_warnings ON rs.ws_item_sk = rs_warnings.wr_item_sk
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 50 AND
        COALESCE(rs.ws_net_profit, 0) > 1000
)
SELECT 
    fs.sales_rank,
    fs.quantity_sold,
    fs.net_profit,
    fs.sales_price,
    fs.avg_profit_per_unit,
    CASE 
        WHEN fs.net_quantity < 0 THEN 'Oversold'
        ELSE 'Balanced'
    END AS stock_status
FROM 
    Final_Summary fs
ORDER BY 
    fs.sales_rank, fs.net_profit DESC
LIMIT 10;
