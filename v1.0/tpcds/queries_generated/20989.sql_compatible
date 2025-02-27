
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_quantity,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
),
high_value_items AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        (id.total_catalog_quantity + id.total_store_quantity) AS combined_sales,
        COALESCE(rs.total_sales, 0) AS web_sales
    FROM item_details id
    LEFT JOIN ranked_sales rs ON id.i_item_sk = rs.ws_item_sk
    WHERE (id.total_catalog_quantity + id.total_store_quantity) > (
        SELECT AVG(total_sales) 
        FROM ranked_sales 
        WHERE rn <= 10
    )
)
SELECT 
    hvi.i_item_sk,
    hvi.i_item_desc,
    CASE 
        WHEN hvi.web_sales IS NULL THEN 'No web sales'
        ELSE CONCAT('Web sales total: ', CAST(hvi.web_sales AS VARCHAR(255)))
    END AS sales_summary,
    CASE 
        WHEN hvi.combined_sales = 0 THEN 'Not sold'
        ELSE 'Sold'
    END AS sales_status
FROM high_value_items hvi
WHERE NOT EXISTS (
    SELECT 1 FROM store s 
    WHERE s.s_country = 'United States'
    AND s.s_store_sk IN (
        SELECT ss_store_sk
        FROM store_sales ss 
        WHERE ss.ss_item_sk = hvi.i_item_sk 
        AND ss.ss_sold_date_sk = (
            SELECT MAX(ss1.ss_sold_date_sk) FROM store_sales ss1 WHERE ss1.ss_item_sk = hvi.i_item_sk
        )
    )
)
ORDER BY hvi.web_sales DESC, hvi.i_item_desc
FETCH FIRST 20 ROWS ONLY;
