
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price) > 10000
    UNION ALL
    SELECT cs_item_sk, SUM(cs_sales_price) + sh.total_sales
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_item_sk = sh.ws_item_sk
    GROUP BY cs_item_sk
),
ranked_sales AS (
    SELECT item.i_item_id,
           item.i_item_desc,
           COALESCE(sh.total_sales, 0) AS total_sales,
           RANK() OVER (ORDER BY COALESCE(sh.total_sales, 0) DESC) AS sales_rank
    FROM item
    LEFT JOIN sales_hierarchy sh ON item.i_item_sk = sh.ws_item_sk
),
top_sales AS (
    SELECT i_item_id, i_item_desc, total_sales, sales_rank
    FROM ranked_sales
    WHERE sales_rank <= 10
)
SELECT ts.i_item_id,
       ts.i_item_desc,
       ts.total_sales,
       CASE 
           WHEN ts.total_sales > 50000 THEN 'High Performer'
           WHEN ts.total_sales BETWEEN 20000 AND 50000 THEN 'Moderate Performer'
           ELSE 'Low Performer'
       END AS performance_category,
       d.d_year AS sales_year,
       COALESCE(a.ca_country, 'Unknown') AS country
FROM top_sales ts
JOIN date_dim d ON d.d_date_sk = (SELECT MIN(ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_item_sk = ts.i_item_id)
LEFT JOIN customer_address a ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ts.i_item_id LIMIT 1))
WHERE ts.total_sales IS NOT NULL
ORDER BY ts.total_sales DESC;
