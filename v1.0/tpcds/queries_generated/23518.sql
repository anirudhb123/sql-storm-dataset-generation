
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS RankSales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_quantity DESC) AS DenseRankQuantity
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 5 AND c.c_birth_year BETWEEN 1980 AND 1990
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_ext_sales_price) AS TotalSales
    FROM RankedSales rs
    WHERE rs.RankSales <= 10
    GROUP BY rs.web_site_sk
),
AverageSales AS (
    SELECT 
        web_site_sk,
        AVG(TotalSales) AS AvgTotalSales
    FROM TopSales
    GROUP BY web_site_sk
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        sm.sm_type
    FROM ship_mode sm
    WHERE sm.sm_type LIKE '%Ground%'
)
SELECT 
    ws.web_site_sk,
    SUM(ws.ws_ext_sales_price) AS TotalSales,
    AVG(ws.ws_ext_sales_price) AS AvgSalesPerOrder,
    CASE 
        WHEN AVG(ws.ws_ext_sales_price) IS NULL THEN 'No Sales'
        WHEN AVG(ws.ws_ext_sales_price) > 100 THEN 'High Value'
        ELSE 'Standard Value'
    END AS ValueCategory,
    COALESCE(AVG(AvgTotalSales), 0) AS AverageTopSales,
    COUNT(DISTINCT sm.sm_ship_mode_id) AS DistinctShippingModes
FROM 
    web_sales ws
LEFT JOIN 
    AverageSales as ON ws.ws_web_site_sk = as.web_site_sk
JOIN 
    ShippingModes sm ON sm.sm_ship_mode_id = CASE 
        WHEN ws.ws_quantity > 5 THEN 'Standard'
        ELSE 'Express'
    END
WHERE 
    ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_dow IN (1, 2, 3, 4, 5)
    )
AND EXISTS (
    SELECT 1 
    FROM store_sales ss 
    WHERE ss.ss_item_sk = ws.ws_item_sk AND ss.ss_quantity > 0
)
GROUP BY 
    ws.web_site_sk
HAVING 
    SUM(ws.ws_quantity) > 15
ORDER BY 
    TotalSales DESC
FETCH FIRST 10 ROWS ONLY;
