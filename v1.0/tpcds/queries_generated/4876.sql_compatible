
WITH item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(ws.ws_quantity) AS total_web_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM 
        item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE 
        i.i_current_price > 50
    GROUP BY 
        i.i_item_id
),
sales_by_channel AS (
    SELECT 
        i_item_id,
        (total_catalog_sales + total_web_sales + total_store_sales) AS total_sales,
        CASE 
            WHEN total_catalog_sales >= total_web_sales AND total_catalog_sales >= total_store_sales THEN 'Catalog'
            WHEN total_web_sales >= total_catalog_sales AND total_web_sales >= total_store_sales THEN 'Web'
            ELSE 'Store'
        END AS preferred_channel
    FROM 
        item_sales
),
ranked_sales AS (
    SELECT 
        i_item_id,
        total_sales,
        preferred_channel,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_by_channel
)
SELECT 
    rs.i_item_id,
    rs.total_sales,
    rs.preferred_channel,
    COALESCE(d.d_year, 'Unknown') AS sales_year,
    CASE 
        WHEN sales_rank <= 10 THEN 'Top 10 Sales'
        ELSE 'Other Sales'
    END AS sales_category
FROM 
    ranked_sales rs
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
WHERE 
    rs.preferred_channel IS NOT NULL
ORDER BY 
    rs.total_sales DESC;
