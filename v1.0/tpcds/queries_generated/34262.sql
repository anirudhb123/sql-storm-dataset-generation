
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, 1 AS level
    FROM date_dim
    WHERE d_date >= '2022-01-01' AND d_date < '2023-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, h.level + 1
    FROM date_dim d
    JOIN DateHierarchy h ON d.d_year = h.d_year + 1
    WHERE h.level < 5
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS average_price
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
InventoryCheck AS (
    SELECT 
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk
),
CombinedData AS (
    SELECT 
        dh.d_date AS sale_date,
        sd.total_sales,
        sd.order_count,
        sd.average_price,
        COALESCE(ic.total_inventory, 0) AS total_inventory
    FROM DateHierarchy dh
    LEFT JOIN SalesData sd ON dh.d_date_sk = sd.ws_sold_date_sk
    LEFT JOIN InventoryCheck ic ON dh.d_date_sk = ic.inv_date_sk
)
SELECT 
    sale_date,
    total_sales,
    order_count,
    average_price,
    total_inventory,
    CASE 
        WHEN total_sales > 10000 THEN 'High'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (total_sales / NULLIF(total_inventory, 0)) AS sales_to_inventory_ratio
FROM CombinedData
WHERE total_inventory IS NOT NULL
ORDER BY sale_date DESC
LIMIT 10;
