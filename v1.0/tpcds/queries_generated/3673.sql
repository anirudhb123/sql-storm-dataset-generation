
WITH item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales,
        ROW_NUMBER() OVER(PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_net_profit) DESC) AS web_rank,
        ROW_NUMBER() OVER(PARTITION BY i.i_item_id ORDER BY SUM(cs.cs_net_profit) DESC) AS catalog_rank,
        ROW_NUMBER() OVER(PARTITION BY i.i_item_id ORDER BY SUM(ss.ss_net_profit) DESC) AS store_rank
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_id
),
ranked_sales AS (
    SELECT 
        i_item_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        web_rank,
        catalog_rank,
        store_rank
    FROM item_sales
    WHERE total_web_sales IS NOT NULL OR total_catalog_sales IS NOT NULL OR total_store_sales IS NOT NULL
),
best_selling_items AS (
    SELECT 
        ir.i_item_id,
        ir.total_web_sales,
        ir.total_catalog_sales,
        ir.total_store_sales,
        COALESCE(ir.web_rank, 0) AS web_rank,
        COALESCE(ir.catalog_rank, 0) AS catalog_rank,
        COALESCE(ir.store_rank, 0) AS store_rank
    FROM ranked_sales ir
    WHERE ir.web_rank <= 10 OR ir.catalog_rank <= 10 OR ir.store_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(b.total_web_sales, 0) AS web_sales,
    COALESCE(b.total_catalog_sales, 0) AS catalog_sales,
    COALESCE(b.total_store_sales, 0) AS store_sales,
    CASE 
        WHEN b.total_web_sales = (
            SELECT MAX(total_web_sales) FROM ranked_sales
        ) THEN 'Best Web Seller'
        WHEN b.total_catalog_sales = (
            SELECT MAX(total_catalog_sales) FROM ranked_sales
        ) THEN 'Best Catalog Seller'
        WHEN b.total_store_sales = (
            SELECT MAX(total_store_sales) FROM ranked_sales
        ) THEN 'Best Store Seller'
        ELSE 'Regular Seller'
    END AS seller_type
FROM item i
LEFT JOIN best_selling_items b ON i.i_item_id = b.i_item_id
WHERE i.i_item_id IS NOT NULL
ORDER BY web_sales DESC, catalog_sales DESC, store_sales DESC;
