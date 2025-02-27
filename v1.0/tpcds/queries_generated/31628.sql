
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_ext_sales_price) + cte.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk) AS rn
    FROM 
        catalog_sales cs
    JOIN 
        sales_cte cte ON cs.cs_order_number = cte.ws_item_sk
    GROUP BY 
        cs_sold_date_sk, cs_item_sk, cte.total_sales
),
total_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(sales.total_sales), 0) AS grand_total_sales
    FROM 
        item
    LEFT JOIN 
        sales_cte sales ON item.i_item_sk = sales.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.grand_total_sales,
    CASE
        WHEN ts.grand_total_sales > 5000 THEN 'High Performer'
        WHEN ts.grand_total_sales BETWEEN 1000 AND 5000 THEN 'Average Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    total_sales ts
WHERE 
    ts.grand_total_sales IS NOT NULL
ORDER BY 
    ts.grand_total_sales DESC
LIMIT 10;
