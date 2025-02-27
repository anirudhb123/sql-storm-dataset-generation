
WITH item_sales AS (
    SELECT 
        i.i_item_id, 
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_id
),
income_distribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY hd.hd_income_band_sk
),
top_items AS (
    SELECT 
        item_sales.i_item_id,
        item_sales.total_web_sales,
        item_sales.total_catalog_sales,
        item_sales.total_store_sales,
        RANK() OVER (ORDER BY (item_sales.total_web_sales + item_sales.total_catalog_sales + item_sales.total_store_sales) DESC) AS sales_rank
    FROM item_sales
)
SELECT 
    ti.i_item_id,
    ti.total_web_sales,
    ti.total_catalog_sales,
    ti.total_store_sales,
    id.num_customers,
    (CASE 
        WHEN id.num_customers IS NULL THEN 'Unknown' 
        ELSE (CASE 
            WHEN id.num_customers > 100 THEN 'High' 
            WHEN id.num_customers BETWEEN 51 AND 100 THEN 'Medium' 
            ELSE 'Low' 
        END) 
    END) AS customer_segment
FROM top_items ti
LEFT JOIN income_distribution id ON ti.i_item_id = id.hd_income_band_sk
WHERE ti.sales_rank <= 10
ORDER BY ti.sales_rank;
