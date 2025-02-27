
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(cs_sales_price) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
), 
Total_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(sc.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(sc.total_sales), 0) AS total_sales,
        SUM(CASE WHEN sc.rank IS NOT NULL THEN 1 ELSE 0 END) AS sale_count
    FROM 
        item
    LEFT JOIN 
        Sales_CTE sc ON item.i_item_sk = sc.ws_item_sk OR item.i_item_sk = sc.cs_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    ta.i_item_id,
    ta.i_item_desc,
    ta.total_quantity,
    ta.total_sales,
    ta.sale_count,
    CASE 
        WHEN ta.total_sales > 1000 THEN 'High'
        WHEN ta.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    Total_Sales ta
WHERE 
    ta.total_quantity > (
        SELECT AVG(total_quantity) FROM Total_Sales
    ) OR 
    ta.total_sales IS NULL
ORDER BY 
    ta.total_sales DESC
LIMIT 10;
