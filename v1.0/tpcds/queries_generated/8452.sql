
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ws.ws_sold_date_sk BETWEEN 2458866 AND 2459146  -- Filtered date range
),
TotalSales AS (
    SELECT 
        r.web_site_sk,
        SUM(r.ws_sales_price * r.ws_quantity) AS TotalSalesValue,
        COUNT(r.ws_order_number) AS TotalOrders
    FROM 
        RankedSales r
    WHERE 
        r.SalesRank <= 10  -- Top 10 sales per site
    GROUP BY 
        r.web_site_sk
)
SELECT 
    w.web_site_id,
    ts.TotalSalesValue,
    ts.TotalOrders,
    COUNT(DISTINCT r.ws_order_number) AS DistinctOrderCount
FROM 
    TotalSales ts
JOIN 
    web_site w ON ts.web_site_sk = w.web_site_sk
JOIN 
    web_sales r ON r.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M')
GROUP BY 
    w.web_site_id, ts.TotalSalesValue, ts.TotalOrders
ORDER BY 
    TotalSalesValue DESC
LIMIT 5;  -- Top 5 websites by total sales value
