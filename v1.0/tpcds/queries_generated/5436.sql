
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS TotalSales,
        COUNT(ws.ws_order_number) AS OrderCount,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_id,
        TotalSales,
        OrderCount
    FROM 
        RankedSales
    WHERE 
        SalesRank <= 5
)
SELECT 
    ts.web_site_id,
    ts.TotalSales,
    ts.OrderCount,
    w.w_warehouse_name,
    SUM(cs.cs_quantity) AS TotalQuantitySold,
    SUM(cs.cs_net_profit) AS TotalNetProfit
FROM 
    TopSales ts
JOIN 
    warehouse w ON ts.web_site_id = w.w_warehouse_id
LEFT JOIN 
    catalog_sales cs ON cs.cs_order_number = ts.ws_order_number
GROUP BY 
    ts.web_site_id, ts.TotalSales, ts.OrderCount, w.w_warehouse_name
ORDER BY 
    ts.TotalSales DESC;
