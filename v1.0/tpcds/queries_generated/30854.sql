
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk, s_store_name, COUNT(ss.ticket_number) AS total_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s_store_sk, s_store_name
    UNION ALL
    SELECT sh.s_store_sk, sh.s_store_name, sh.total_sales + COALESCE(ss.total_sales, 0)
    FROM SalesHierarchy sh
    LEFT JOIN (
        SELECT s_store_sk, COUNT(ss.ticket_number) AS total_sales
        FROM store s
        LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
        GROUP BY s_store_sk
    ) ss ON ss.s_store_sk = sh.s_store_sk
    WHERE ss.total_sales IS NOT NULL
),
ItemSales AS (
    SELECT i.i_item_sk, i.i_item_id, SUM(ss.ss_sales_price) AS total_sales_price
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
MaxSales AS (
    SELECT i_item_sk, MAX(total_sales_price) AS max_sales
    FROM ItemSales
    GROUP BY i_item_sk
),
CustomerOverview AS (
    SELECT c.c_customer_sk, COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
           SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT s.s_store_name, 
       sh.total_sales, 
       io.total_sales_price, 
       COALESCE(co.returns_count, 0) AS returns_count,
       COALESCE(co.total_returns, 0) AS total_returns,
       CASE WHEN sh.total_sales > 100 THEN 'High Seller' ELSE 'Low Seller' END AS sales_category
FROM SalesHierarchy sh
JOIN store s ON sh.s_store_sk = s.s_store_sk
JOIN ItemSales io ON s.s_store_sk = io.i_item_sk
LEFT JOIN CustomerOverview co ON s.s_store_sk = co.c_customer_sk
WHERE io.total_sales_price > (SELECT AVG(total_sales_price) FROM ItemSales)
ORDER BY sh.total_sales DESC, io.total_sales_price DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
