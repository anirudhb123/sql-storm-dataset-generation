
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT cs_sold_date_sk,
           SUM(cs_ext_sales_price) + SUM(total_sales) AS total_sales,
           COUNT(DISTINCT cs_order_number) + order_count AS order_count,
           DENSE_RANK() OVER (ORDER BY SUM(cs_ext_sales_price) + SUM(total_sales) DESC) AS sales_rank
    FROM catalog_sales
    JOIN SalesCTE ON cs_sold_date_sk = ws_sold_date_sk
    GROUP BY cs_sold_date_sk
),
TopSales AS (
    SELECT d.d_date,
           s.sales_rank,
           s.total_sales,
           s.order_count
    FROM SalesCTE s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    WHERE s.sales_rank <= 10
)
SELECT COALESCE(SUM(ss_ext_sales_price), 0) AS store_total_sales,
       COALESCE(SUM(ss_quantity), 0) AS total_store_quantity,
       str.lower(SUBSTRING(SUM(ss_ext_sales_price) + COALESCE(SUM(cs_ext_sales_price), 0) + COALESCE(SUM(ws_ext_sales_price), 0)::text, 1, 10)) AS sales_prefix,
       t.order_count
FROM store_sales ss 
LEFT JOIN TopSales t ON ss.ss_sold_date_sk = t.sales_rank
WHERE ss.ss_sold_date_sk IS NOT NULL 
GROUP BY t.order_count
HAVING SUM(ss_ext_sales_price) > t.total_sales
ORDER BY store_total_sales DESC;
