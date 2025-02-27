
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        wd.d_year,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM
        web_sales ws
    JOIN
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    WHERE
        wd.d_year BETWEEN 2020 AND 2023
),
HighValueSales AS (
    SELECT
        web_site_sk,
        SUM(ws_sales_price * ws_quantity) AS TotalSales
    FROM
        RankedSales
    WHERE
        PriceRank <= 10
    GROUP BY
        web_site_sk
)
SELECT
    w.warehouse_id,
    w.warehouse_name,
    CASE 
        WHEN hvs.TotalSales IS NOT NULL THEN hvs.TotalSales 
        ELSE 0 
    END AS TotalSales,
    (SELECT COUNT(*) FROM web_sales WHERE ws_web_site_sk = w.warehouse_sk) AS TotalOrders
FROM 
    warehouse w
LEFT JOIN 
    HighValueSales hvs ON w.warehouse_sk = hvs.web_site_sk
ORDER BY
    TotalSales DESC
LIMIT 20;
