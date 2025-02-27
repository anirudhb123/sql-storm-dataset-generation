
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i_item_sk, 
        i_item_id, 
        i_current_price,
        CAST(i_item_desc AS VARCHAR(255)) AS full_desc, 
        1 AS hierarchy_level 
    FROM 
        item 
    WHERE 
        i_current_price IS NOT NULL 

    UNION ALL 

    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_current_price,
        CONCAT(ih.full_desc, ' > ', i.i_item_desc),
        ih.hierarchy_level + 1
    FROM 
        item i
    JOIN 
        ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE 
        ih.hierarchy_level < 5  -- Limit depth to 5 levels
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales 
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 -- Last 30 days of 2023
    GROUP BY 
        ws.ws_item_sk
), 
HighestSales AS (
    SELECT 
        id.i_item_id,
        id.full_desc,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        ItemHierarchy id
    JOIN 
        SalesData sd ON id.i_item_sk = sd.ws_item_sk
)
SELECT 
    hs.i_item_id,
    hs.full_desc,
    hs.total_quantity,
    hs.total_sales,
    CASE 
        WHEN hs.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Others' 
    END AS sales_category 
FROM 
    HighestSales hs
WHERE 
    hs.total_sales IS NOT NULL 
ORDER BY 
    hs.total_sales DESC
LIMIT 50;
