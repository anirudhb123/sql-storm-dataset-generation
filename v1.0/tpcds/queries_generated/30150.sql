
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        1 AS depth
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2455054 AND 2455369  -- Filters for specific date range
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        depth + 1
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2455054 AND 2455369 AND
        cs_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk >= 2455054)
),
Item_Sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(SALES.ws_quantity) AS total_web_quantity,
        COALESCE(SUM(SALES.ws_ext_sales_price), 0) AS total_web_sales,
        (SELECT AVG(ws_ext_sales_price) FROM web_sales WHERE ws_item_sk = i.i_item_sk) AS avg_web_price,
        (SELECT COUNT(*) FROM web_sales WHERE ws_item_sk = i.i_item_sk) AS web_sales_count
    FROM 
        item i
    LEFT JOIN 
        web_sales SALES ON i.i_item_sk = SALES.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
Aggregate_Sales AS (
    SELECT 
        item_id,
        item_desc,
        total_web_quantity,
        total_web_sales,
        avg_web_price,
        web_sales_count,
        RANK() OVER (ORDER BY total_web_sales DESC) as sales_rank
    FROM 
        Item_Sales
)
SELECT 
    item_id,
    item_desc,
    total_web_quantity,
    total_web_sales, 
    avg_web_price,
    web_sales_count,
    CASE 
        WHEN total_web_sales IS NULL THEN 'No Sales'
        WHEN total_web_quantity < 50 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    Aggregate_Sales
WHERE 
    sales_rank <= 10
ORDER BY 
    total_web_sales DESC;
