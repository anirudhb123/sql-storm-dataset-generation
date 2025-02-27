
WITH RankedSales AS (
    SELECT 
        w.warehouse_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.warehouse_name
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
SalesAndReturns AS (
    SELECT 
        r.warehouse_name,
        rs.total_sales,
        rs.total_orders,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.avg_return_qty, 0) AS avg_return_qty
    FROM 
        RankedSales rs
    LEFT JOIN 
        warehouse r ON r.warehouse_name = rs.warehouse_name
    LEFT JOIN 
        CustomerReturns cr ON cr.sr_store_sk = r.w_warehouse_sk
)
SELECT 
    warehouse_name,
    total_sales,
    total_orders,
    return_count,
    total_return_amt,
    avg_return_qty,
    (total_sales - total_return_amt) AS net_sales,
    CASE 
        WHEN total_orders = 0 THEN 0 
        ELSE (total_sales - total_return_amt) / total_orders 
    END AS avg_net_per_order
FROM 
    SalesAndReturns
WHERE 
    return_count > 0 OR total_orders > 0
ORDER BY 
    net_sales DESC
LIMIT 10;
