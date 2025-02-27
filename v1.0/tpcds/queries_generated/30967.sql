
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        v.ws_sold_date_sk,
        v.ws_item_sk,
        v.total_quantity + s.total_quantity,
        v.total_sales + s.total_sales
    FROM 
        Sales_CTE s
    JOIN 
        web_sales v ON s.ws_item_sk = v.ws_item_sk AND v.ws_sold_date_sk < s.ws_sold_date_sk
),
Filtered_Sales AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS total_sales,
        COUNT(*) AS sales_count
    FROM 
        Sales_CTE
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(fs.total_sales, 0) AS total_sales,
    fs.sales_count,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY COALESCE(fs.total_sales, 0) DESC) AS sales_rank
FROM 
    item i
LEFT JOIN 
    Filtered_Sales fs ON i.i_item_sk = fs.ws_item_sk
WHERE 
    i.i_current_price > 0
    AND i.i_item_desc LIKE '%Gadget%'
    AND (fs.total_sales IS NULL OR fs.total_sales > 1000)
ORDER BY 
    sales_rank;
