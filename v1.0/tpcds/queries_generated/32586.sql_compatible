
WITH RECURSIVE sales_summary AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS row_num
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451531 AND 2451540
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, 
           SUM(cs_quantity) AS total_quantity,
           SUM(cs_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC)
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451531 AND 2451540
    GROUP BY cs_item_sk
),
aggregated_sales AS (
    SELECT item_sk, 
           SUM(total_quantity) AS overall_quantity,
           SUM(total_sales) AS overall_sales
    FROM (
        SELECT ws_item_sk AS item_sk, total_quantity, total_sales FROM sales_summary
        UNION ALL
        SELECT cs_item_sk AS item_sk, total_quantity, total_sales FROM sales_summary
    ) AS combined_sales
    GROUP BY item_sk
),
top_items AS (
    SELECT item_sk,
           overall_quantity,
           overall_sales,
           DENSE_RANK() OVER (ORDER BY overall_sales DESC) AS sales_rank
    FROM aggregated_sales
)
SELECT c.c_first_name, 
       c.c_last_name,
       ca.ca_city,
       ti.item_sk,
       ti.overall_quantity,
       ti.overall_sales
FROM top_items ti
LEFT JOIN customer c ON c.c_customer_sk IN (
    SELECT sr_customer_sk
    FROM store_returns
    WHERE sr_item_sk = ti.item_sk
)
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ti.sales_rank <= 10 AND 
      ti.overall_sales IS NOT NULL
ORDER BY ti.overall_sales DESC;
