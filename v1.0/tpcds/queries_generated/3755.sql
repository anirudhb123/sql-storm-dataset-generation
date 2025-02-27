
WITH ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(DISTINCT i.i_item_id) AS promo_item_count
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_sk, p.p_promo_id, p.p_start_date_sk, p.p_end_date_sk
)
SELECT
    iis.i_item_id,
    iis.total_web_sales,
    iis.total_catalog_sales,
    iis.total_store_sales,
    iis.total_sales,
    COALESCE(p.p_promo_id, 'No Promotion') AS promotion_id,
    CASE 
        WHEN iis.total_sales > 1000 THEN 'High Seller'
        WHEN iis.total_sales BETWEEN 500 AND 1000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS seller_category,
    DENSE_RANK() OVER (ORDER BY iis.total_sales DESC) AS sales_rank
FROM ItemSales iis
LEFT JOIN Promotions p ON iis.i_item_sk = p.p_promo_sk
WHERE iis.total_sales > (
    SELECT AVG(total_sales)
    FROM ItemSales
) 
ORDER BY iis.total_sales DESC
LIMIT 10;
