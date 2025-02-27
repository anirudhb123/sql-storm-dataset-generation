
WITH RECURSIVE ProductHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, 0 AS level
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)

    UNION ALL

    SELECT p.i_item_sk, p.i_item_id, p.i_item_desc, ph.level + 1
    FROM item p
    INNER JOIN ProductHierarchy ph ON p.i_item_sk = ph.i_item_sk
    WHERE p.i_current_price > 20.00
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > 24700  -- example date as a threshold
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        pi.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        DENSE_RANK() OVER (PARTITION BY sd.ws_sold_date_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    JOIN ProductHierarchy pi ON sd.ws_item_sk = pi.i_item_sk
)
SELECT 
    d.d_date AS SaleDate,
    rs.i_item_desc AS ItemDescription,
    rs.total_quantity AS QuantitySold,
    rs.total_sales AS TotalSales,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        WHEN rs.sales_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS SalesCategory
FROM RankedSales rs
JOIN date_dim d ON rs.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023
ORDER BY d.d_date, rs.total_sales DESC
LIMIT 100;
