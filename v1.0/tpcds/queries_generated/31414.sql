
WITH RECURSIVE CTE_Sales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    UNION ALL
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) + cte.total_quantity,
        SUM(ws.ws_net_paid) + cte.total_sales,
        cte.level + 1
    FROM 
        web_sales ws
    JOIN 
        CTE_Sales cte ON ws.ws_item_sk = cte.ss_item_sk
    GROUP BY 
        ws.ws_item_sk, cte.total_quantity, cte.total_sales, cte.level
),
MaxSales AS (
    SELECT 
        item.i_item_id,
        s.total_quantity,
        s.total_sales,
        RANK() OVER (PARTITION BY item.i_item_category ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        item item
    JOIN 
        CTE_Sales s ON item.i_item_sk = s.ss_item_sk
),
FilteredMaxSales AS (
    SELECT 
        m.item_id,
        m.total_quantity,
        m.total_sales
    FROM 
        MaxSales m
    WHERE 
        m.sales_rank <= 10
)
SELECT 
    DISTINCT f.item_id,
    f.total_quantity,
    f.total_sales,
    CASE 
        WHEN f.total_sales IS NULL THEN 'No Sales Data' 
        ELSE 'Sales Data Available' 
    END AS sales_status,
    COALESCE(ROUND(f.total_sales * 1.2, 2), 0) AS adjusted_sales
FROM 
    FilteredMaxSales f
LEFT JOIN 
    reason r ON f.total_quantity = r.r_reason_sk
WHERE 
    f.total_quantity IS NOT NULL
ORDER BY 
    f.total_sales DESC;
