
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
PromotionCTE AS (
    SELECT 
        p_item_sk,
        p_discount_active,
        COUNT(DISTINCT p_promo_id) AS promo_count
    FROM 
        promotion
    GROUP BY 
        p_item_sk, p_discount_active
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(total_sales, 0) AS total_sales,
        COALESCE(order_count, 0) AS order_count,
        pd.promo_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY COALESCE(total_sales, 0) DESC) AS item_rank
    FROM 
        item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN PromotionCTE pd ON i.i_item_sk = pd.p_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.total_sales,
    id.order_count,
    id.promo_count,
    (CASE 
        WHEN id.total_sales IS NULL THEN 'No Sales'
        WHEN id.total_sales > 1000 THEN 'High Seller'
        ELSE 'Low Seller'
     END) AS sales_category,
     (SELECT COUNT(*) 
      FROM item x 
      WHERE x.i_item_sk < id.i_item_sk) AS items_ranking_position
FROM 
    ItemDetails id
WHERE 
    id.item_rank <= 10
ORDER BY 
    id.total_sales DESC
UNION ALL
SELECT 
    NULL AS i_item_sk,
    'Total Sales' AS i_item_desc,
    SUM(total_sales) AS total_sales,
    NULL AS order_count,
    NULL AS promo_count,
    NULL AS sales_category,
    NULL AS items_ranking_position
FROM 
    ItemDetails
HAVING 
    SUM(total_sales) > 5000
ORDER BY 
    total_sales DESC;
