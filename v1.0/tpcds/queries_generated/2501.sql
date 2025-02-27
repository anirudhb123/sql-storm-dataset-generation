
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451826 -- Sample date range
),
AvgSales AS (
    SELECT 
        rs.ws_item_sk,
        AVG(rs.ws_ext_sales_price) AS avg_sales_price
    FROM RankedSales rs
    WHERE rs.sales_rank <= 10
    GROUP BY rs.ws_item_sk
),
HighestSellingItems AS (
    SELECT 
        ir.i_item_id,
        ir.i_item_desc,
        COALESCE(ars.avg_sales_price, 0) AS avg_price,
        SUM(ws.ws_quantity) AS total_quantity
    FROM RankedSales r
    JOIN item ir ON r.ws_item_sk = ir.i_item_sk
    LEFT JOIN AvgSales ars ON r.ws_item_sk = ars.ws_item_sk
    GROUP BY ir.i_item_id, ir.i_item_desc, ars.avg_sales_price
    ORDER BY total_quantity DESC
    LIMIT 20
)
SELECT 
    hsi.i_item_id,
    hsi.i_item_desc,
    hsi.avg_price,
    (CASE 
        WHEN hsi.avg_price > 100 THEN 'High'
        WHEN hsi.avg_price BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END) AS price_band,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM HighestSellingItems hsi
JOIN web_sales ws ON hsi.i_item_id = ws.ws_item_sk
GROUP BY hsi.i_item_id, hsi.i_item_desc, hsi.avg_price
HAVING order_count > 5
ORDER BY order_count DESC
```
