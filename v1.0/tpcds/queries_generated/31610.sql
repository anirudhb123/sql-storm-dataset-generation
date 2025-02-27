
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
), 
Top_Sales AS (
    SELECT 
        w.w_warehouse_id,
        sc.total_quantity,
        sc.total_net_profit
    FROM 
        Sales_CTE sc
    JOIN 
        warehouse w ON sc.w_warehouse_sk = w.w_warehouse_sk
    WHERE 
        sc.rank <= 10
), 
Customer_Returns AS (
    SELECT 
        c.c_customer_sk,
        SUM(sr_return_qty) AS total_return_qty,
        COUNT(cr_returning_customer_sk) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
Return_Statistics AS (
    SELECT 
        cr.c_customer_sk,
        SUM(CASE WHEN cr.total_return_qty IS NOT NULL THEN cr.total_return_qty ELSE 0 END) AS total_return_qty,
        COUNT(*) AS return_count
    FROM 
        Customer_Returns cr
    GROUP BY 
        cr.c_customer_sk
)
SELECT 
    ts.w_warehouse_id,
    ts.total_quantity,
    ts.total_net_profit,
    COALESCE(rs.total_return_qty, 0) AS total_customer_return_qty,
    rs.return_count
FROM 
    Top_Sales ts
LEFT JOIN 
    Return_Statistics rs ON ts.w_warehouse_id = (SELECT TOP 1 c.c_customer_id FROM customer c WHERE c.c_customer_sk = rs.c_customer_sk);
