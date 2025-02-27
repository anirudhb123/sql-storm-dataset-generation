
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        total_quantity_sold + cs_quantity
    FROM catalog_sales cs
    JOIN Sales_CTE s ON cs.cs_sold_date_sk = s.ws_sold_date_sk AND cs.cs_item_sk = s.ws_item_sk
),
Item_Sales AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(s.total_quantity_sold), 0) AS total_sold,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN Sales_CTE s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = s.ws_item_sk
    GROUP BY i.i_item_id
),
Sales_Avg AS (
    SELECT 
        total_sold,
        AVG(total_sold) OVER () AS avg_sales,
        CASE 
            WHEN total_sold > AVG(total_sold) OVER () THEN 'Above Average'
            WHEN total_sold < AVG(total_sold) OVER () THEN 'Below Average'
            ELSE 'Average'
        END AS sales_category
    FROM Item_Sales
),
High_Sales AS (
    SELECT 
        i.i_item_id,
        s.sales_category,
        s.total_sold
    FROM Item_Sales i
    JOIN Sales_Avg s ON i.total_sold > s.avg_sales
)
SELECT 
    h.i_item_id,
    h.sales_category,
    h.total_sold,
    COALESCE(d.d_day_name, 'Unknown') AS day_name,
    (SELECT SUM(ws_net_profit) FROM web_sales w WHERE w.ws_item_sk = h.total_sold) AS total_net_profit,
    CASE 
        WHEN h.total_sold IS NULL THEN 'No sales data'
        ELSE 'Sales data available'
    END AS data_status
FROM High_Sales h
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT ws_sold_date_sk FROM web_sales WHERE ws_item_sk = h.total_sold LIMIT 1)
ORDER BY h.total_sold DESC;
