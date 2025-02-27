
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_brand, i_category, 1 AS depth
    FROM item
    WHERE i_current_price IS NOT NULL

    UNION ALL

    SELECT ih.i_item_sk, ih.i_item_id, ih.i_product_name, ih.i_brand, ih.i_category, depth + 1
    FROM ItemHierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.depth < 5
),
CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT s.s_store_sk, s.s_store_name, 
           COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
           COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
SalesSummary AS (
    SELECT 'Web' AS sales_channel, cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_web_sales, cs.order_count
    FROM CustomerSales cs
    UNION ALL
    SELECT 'Store' AS sales_channel, NULL AS c_customer_sk, NULL AS c_first_name, NULL AS c_last_name, SUM(ss.total_store_sales), SUM(ss.store_order_count)
    FROM StoreSales ss
)
SELECT sh.sales_channel, 
       COALESCE(sh.c_first_name || ' ' || sh.c_last_name, 'Store Aggregate') AS customer_name,
       COALESCE(sh.total_web_sales, 0) AS total_sales,
       sh.order_count
FROM SalesSummary sh
LEFT JOIN ItemHierarchy ih ON sh.c_customer_sk IS NULL
WHERE (sh.sales_channel = 'Web' OR sh.total_sales > 0)
ORDER BY total_sales DESC
LIMIT 100;
