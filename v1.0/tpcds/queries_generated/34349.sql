
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk AS sold_date,
        ws_item_sk AS item_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        inv_date_sk AS sold_date,
        inv_item_sk AS item_id,
        SUM(inv_quantity_on_hand) AS total_quantity,
        0 AS total_sales
    FROM inventory
    WHERE inv_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY inv_date_sk, inv_item_sk
),
ItemSales AS (
    SELECT
        i_item_id,
        i_item_desc,
        COALESCE(SUM(total_quantity), 0) AS total_quantity,
        COALESCE(SUM(total_sales), 0) AS total_sales
    FROM item
    LEFT JOIN SalesCTE ON item.i_item_sk = SalesCTE.item_id
    GROUP BY i_item_id, i_item_desc
),
SalesSummary AS (
    SELECT 
        i_item_id,
        i_item_desc,
        total_quantity,
        total_sales,
        CASE 
            WHEN total_sales > 0 THEN ROUND((total_sales / NULLIF(total_quantity, 0)), 2)
            ELSE 0 
        END AS avg_price_per_unit
    FROM ItemSales
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_price_per_unit,
    d.d_day_name AS sales_day
FROM SalesSummary ss
JOIN date_dim d ON d.d_date_sk = (
    SELECT MAX(d_date_sk)
    FROM web_sales
)
WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
ORDER BY ss.total_sales DESC
LIMIT 10;
