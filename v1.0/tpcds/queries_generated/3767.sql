
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TotalSales AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS unique_orders
    FROM RankedSales rs
    GROUP BY rs.web_site_sk
),
ReturnCount AS (
    SELECT 
        wr.ws_web_site_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM web_returns wr 
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
    GROUP BY wr.ws_web_site_sk
)
SELECT 
    w.warehouse_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.unique_orders, 0) AS unique_orders,
    COALESCE(rc.total_returns, 0) AS total_returns,
    (COALESCE(ts.total_sales, 0) - COALESCE(rc.total_returns, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(ts.total_sales, 0) = 0 THEN NULL 
        ELSE (COALESCE(rc.total_returns, 0) * 100.0 / COALESCE(ts.total_sales, 0))
    END AS return_percentage
FROM warehouse w
LEFT JOIN TotalSales ts ON w.warehouse_sk = ts.web_site_sk
LEFT JOIN ReturnCount rc ON w.warehouse_sk = rc.ws_web_site_sk
WHERE (ts.total_sales > 1000 OR rc.total_returns IS NOT NULL)
ORDER BY net_sales DESC
LIMIT 10;
