
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_brand, i_class, i_category, 1 AS depth
    FROM item
    WHERE i_item_id LIKE 'A%'
    
    UNION ALL
    
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_brand, i.i_class, i.i_category, ih.depth + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.depth < 5
), sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), customer_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
), reason_summary AS (
    SELECT r.r_reason_sk, r.r_reason_desc, COUNT(cr.cr_reason_sk) AS return_count
    FROM reason r
    LEFT JOIN catalog_returns cr ON r.r_reason_sk = cr.cr_reason_sk
    GROUP BY r.r_reason_sk, r.r_reason_desc
    HAVING COUNT(cr.cr_reason_sk) > 10
)
SELECT 
    ih.i_item_id,
    ih.i_product_name,
    ih.i_brand,
    ih.i_category,
    sd.total_quantity,
    sd.total_sales,
    sd.avg_sales_price,
    ca.customer_count,
    ca.avg_purchase_estimate,
    rs.return_count,
    CASE 
        WHEN sd.sales_rank = 1 THEN 'Top Seller'
        WHEN sd.total_sales > 1000 THEN 'Moderate Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM item_hierarchy ih
LEFT JOIN sales_data sd ON ih.i_item_sk = sd.ws_item_sk
LEFT JOIN customer_analysis ca ON ca.cd_demo_sk IN (
    SELECT c.c_current_cdemo_sk
    FROM customer c
    WHERE c.c_first_name IS NOT NULL AND c.c_last_name IS NOT NULL
)
LEFT JOIN reason_summary rs ON rs.r_reason_sk IN (
    SELECT cr.cr_reason_sk FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
)
WHERE ih.depth <= 3
ORDER BY total_sales DESC, avg_sales_price DESC;
