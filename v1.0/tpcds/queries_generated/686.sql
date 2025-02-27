
WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        sd.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS sd ON ws.ws_sold_date_sk = sd.d_date_sk
    WHERE 
        sd.d_year = 2023
    GROUP BY 
        w.w_warehouse_id, sd.d_year
),
return_summary AS (
    SELECT
        w.w_warehouse_id,
        sd.d_year,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns AS wr
    JOIN 
        warehouse AS w ON wr.wr_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS sd ON wr.wr_returned_date_sk = sd.d_date_sk
    WHERE 
        sd.d_year = 2023
    GROUP BY 
        w.w_warehouse_id, sd.d_year
)
SELECT 
    ss.w_warehouse_id,
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_profit,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    (ss.total_sales - COALESCE(rs.total_return_amount, 0)) AS net_sales
FROM 
    sales_summary AS ss
LEFT JOIN 
    return_summary AS rs ON ss.w_warehouse_id = rs.w_warehouse_id
ORDER BY 
    net_sales DESC
LIMIT 10;
