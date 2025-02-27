
WITH RECURSIVE address_counts AS (
    SELECT ca_address_sk, ca_city, COUNT(c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_address_sk, ca_city
),
demo_stats AS (
    SELECT cd_gender, COUNT(c_customer_sk) AS demo_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           MAX(cd_credit_rating) AS max_credit_rating,
           MIN(cd_credit_rating) AS min_credit_rating
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
inventory_levels AS (
    SELECT i_item_sk, SUM(inv_quantity_on_hand) AS total_quantity,
           CASE WHEN SUM(inv_quantity_on_hand) OVER (PARTITION BY i_item_sk) > 0 THEN 'In Stock' ELSE 'Out of Stock' END AS stock_status
    FROM inventory
    GROUP BY i_item_sk
),
recent_sales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_sales
    FROM web_sales
    WHERE EXTRACT(YEAR FROM d_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
    GROUP BY ws_item_sk
),
product_performance AS (
    SELECT i_item_sk, i_item_desc,
           COALESCE(SUM(ws_ext_sales_price), 0) AS total_web_sales,
           COALESCE(SUM(cs_ext_sales_price), 0) AS total_catalog_sales,
           COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales,
           COALESCE(r.r_reason_desc, 'No Return') AS return_reason,
           CASE
               WHEN COALESCE(SUM(sr_return_quantity), 0) > 0 THEN 'Returned'
               ELSE 'Not Returned'
           END AS return_status
    FROM item
    LEFT JOIN web_sales ON i_item_sk = ws_item_sk
    LEFT JOIN catalog_sales ON i_item_sk = cs_item_sk
    LEFT JOIN store_sales ON i_item_sk = ss_item_sk
    LEFT JOIN store_returns sr ON sr_item_sk = i_item_sk
    LEFT JOIN reason r ON sr_reason_sk = r.r_reason_sk
    GROUP BY i_item_sk, i_item_desc, r.r_reason_desc
)
SELECT a.ca_city, a.customer_count, d.cd_gender, d.demo_count,
       i.total_quantity, i.stock_status, p.i_item_desc, p.return_status,
       p.total_web_sales, p.total_store_sales, p.total_catalog_sales
FROM address_counts a
JOIN demo_stats d ON a.customer_count = d.demo_count
JOIN inventory_levels i ON a.ca_address_sk = i.i_item_sk
JOIN product_performance p ON p.i_item_sk = i.i_item_sk
WHERE p.total_web_sales > (SELECT AVG(total_web_sales) FROM product_performance)
  AND p.return_status = 'Returned'
  AND (p.total_catalog_sales IS NOT NULL OR p.total_store_sales IS NOT NULL)
ORDER BY a.customer_count DESC, d.demo_count ASC;
