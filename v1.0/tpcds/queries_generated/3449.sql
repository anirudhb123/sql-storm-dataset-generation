
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
OrderStats AS (
    SELECT 
        r.web_site_id,
        SUM(r.ws_sales_price) AS TotalSales,
        COUNT(r.ws_order_number) AS OrderCount
    FROM 
        RankedSales r
    WHERE 
        r.SalesRank <= 10
    GROUP BY 
        r.web_site_id
),
TopWebsites AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        o.TotalSales,
        o.OrderCount,
        (o.TotalSales / NULLIF(o.OrderCount, 0)) AS AvgSalesPerOrder
    FROM 
        web_site ws
    LEFT JOIN 
        OrderStats o ON ws.web_site_id = o.web_site_id
)
SELECT 
    tw.web_site_id,
    tw.web_name,
    COALESCE(tw.TotalSales, 0) AS TotalSales,
    COALESCE(tw.OrderCount, 0) AS OrderCount,
    COALESCE(tw.AvgSalesPerOrder, 0) AS AvgSalesPerOrder
FROM 
    TopWebsites tw
ORDER BY 
    tw.TotalSales DESC
LIMIT 20;
