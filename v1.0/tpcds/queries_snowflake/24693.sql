WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_sales,
        rs.order_count,
        COALESCE(i.i_current_price, 0) AS item_price,
        COALESCE(i.i_brand, 'Unknown') AS item_brand
    FROM 
        RecursiveSales rs
    LEFT JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.total_sales > 1000 AND 
        rs.order_count > 2
),
FinalReport AS (
    SELECT 
        fs.ws_item_sk, 
        fs.total_sales, 
        fs.order_count, 
        fs.item_price, 
        fs.item_brand,
        CASE 
            WHEN fs.total_sales >= 5000 THEN 'High Performer'
            WHEN fs.total_sales BETWEEN 3000 AND 4999 THEN 'Medium Performer'
            ELSE 'Low Performer' 
        END AS performance_category,
        CONCAT('Brand: ', fs.item_brand, ' | Total Sales: ', CAST(fs.total_sales AS CHAR), ' | Order Count: ', CAST(fs.order_count AS CHAR)) AS sales_summary
    FROM 
        FilteredSales fs
)
SELECT 
    fr.ws_item_sk, 
    fr.total_sales, 
    fr.order_count, 
    fr.item_price, 
    fr.item_brand, 
    fr.performance_category, 
    fr.sales_summary
FROM 
    FinalReport fr
WHERE 
    fr.performance_category = 'High Performer'
    OR fr.item_brand LIKE 'A%'
ORDER BY 
    fr.total_sales DESC 
LIMIT 10;