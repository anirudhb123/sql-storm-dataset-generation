
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 1 LIMIT 1)
    GROUP BY ws_item_sk
    UNION ALL 
    SELECT cs_item_sk, SUM(cs_sales_price) AS total_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 1 LIMIT 1)
    GROUP BY cs_item_sk
),
ranked_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sales.total_sales, 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(sales.total_sales, 0) DESC) AS sales_rank
    FROM item
    LEFT JOIN (
        SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales
        FROM web_sales
        GROUP BY ws_item_sk
        UNION ALL
        SELECT cs_item_sk, SUM(cs_sales_price) AS total_sales
        FROM catalog_sales
        GROUP BY cs_item_sk
    ) AS sales ON item.i_item_sk = sales.ws_item_sk OR item.i_item_sk = sales.cs_item_sk
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    AVG(c.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cs_rank.v_rank = 1 THEN cs.total_sales ELSE 0 END) AS top_sales,
    STRING_AGG(DISTINCT item.i_item_desc, ', ') AS top_items
FROM customer_address a
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN (
    SELECT i_item_id, total_sales, sales_rank
    FROM ranked_sales
    WHERE sales_rank <= 10
) AS cs_rank ON cs_rank.i_item_id = c.c_current_hdemo_sk
LEFT JOIN (
    SELECT DISTINCT ws_item_sk, SUM(ws_sales_price) as total_sales
    FROM web_sales
    GROUP BY ws_item_sk
) AS ws_total ON cs_rank.i_item_id = ws_total.ws_item_sk
WHERE a.ca_state = 'CA' 
AND c.cd_marital_status IS NOT NULL 
AND c.cd_gender = 'M' 
GROUP BY a.ca_city
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY total_customers DESC
LIMIT 5;
