
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS recent_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS sales_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
high_value_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.total_sales,
        r.sales_count,
        i.i_item_desc,
        i.i_category,
        COALESCE(p.p_discount_active, 'N') AS active_discount,
        (CASE 
            WHEN r.total_sales > 10000 THEN 'High'
            WHEN r.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END) AS sales_value_category
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk AND p.p_start_date_sk <= r.ws_order_number AND (p.p_end_date_sk IS NULL OR p.p_end_date_sk >= r.ws_order_number)
    WHERE 
        r.recent_rank = 1
),
sales_comparison AS (
    SELECT 
        hvs.ws_item_sk,
        hvs.total_sales,
        hvs.sales_count,
        hvs.i_item_desc,
        hvs.i_category,
        hvs.active_discount,
        hvs.sales_value_category,
        AVG(hvs.total_sales) OVER (PARTITION BY hvs.sales_value_category) AS avg_sales_by_category
    FROM 
        high_value_sales hvs
    JOIN 
        high_value_sales hvs2 ON hvs.i_category = hvs2.i_category AND hvs.ws_item_sk != hvs2.ws_item_sk
    WHERE 
        hvs.total_sales > hvs2.total_sales
)
SELECT 
    sc.ws_item_sk,
    sc.i_item_desc,
    sc.total_sales,
    sc.sales_value_category,
    sc.avg_sales_by_category,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL AND c.c_birth_year BETWEEN 1980 AND 1990) AS customer_count,
    NULLIF((SELECT AVG(ss.sales_price) FROM store_sales ss WHERE ss.ss_item_sk = sc.ws_item_sk AND ss.ss_sold_date_sk < 20200101), 0) AS avg_store_price_before_2020
FROM 
    sales_comparison sc
WHERE 
    sc.total_sales > (SELECT AVG(sc2.total_sales) FROM sales_comparison sc2 WHERE sc2.sales_value_category = sc.sales_value_category)
ORDER BY 
    sc.total_sales DESC
LIMIT 10;
