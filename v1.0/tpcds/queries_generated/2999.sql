
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_sales_price,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
        AND ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT
        rs.web_site_sk,
        SUM(rs.web_sales_price) AS TotalSales,
        COUNT(rs.ws_order_number) AS NumberOfOrders
    FROM
        RankedSales rs
    WHERE
        rs.SalesRank <= 5
    GROUP BY
        rs.web_site_sk
),
SiteStats AS (
    SELECT
        w.warehouse_sk,
        w.warehouse_name,
        COALESCE(ts.TotalSales, 0) AS TotalSales,
        COALESCE(ts.NumberOfOrders, 0) AS NumberOfOrders
    FROM
        warehouse w
    LEFT JOIN
        TopSales ts ON w.warehouse_sk = ts.web_site_sk
),
SalesAnalysis AS (
    SELECT
        s.warehouse_name,
        s.TotalSales,
        s.NumberOfOrders,
        (s.TotalSales / NULLIF(s.NumberOfOrders, 0)) AS AverageOrderValue
    FROM
        SiteStats s
)
SELECT
    sa.warehouse_name,
    sa.TotalSales,
    sa.NumberOfOrders,
    sa.AverageOrderValue,
    CASE
        WHEN sa.AverageOrderValue IS NOT NULL THEN 
            CASE 
                WHEN sa.AverageOrderValue > 100 THEN 'High'
                WHEN sa.AverageOrderValue BETWEEN 50 AND 100 THEN 'Medium'
                ELSE 'Low'
            END
        ELSE 'No Sales'
    END AS SalesCategory
FROM
    SalesAnalysis sa
ORDER BY
    sa.TotalSales DESC;
