
WITH CustomerSales AS (
    SELECT c.c_customer_id,
           SUM(ws.ws_quant) AS total_web_sales,
           SUM(cs.cs_quantity) AS total_catalog_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_id
),
SalesWithRanks AS (
    SELECT c.customer_id,
           c.total_web_sales,
           c.total_catalog_sales,
           RANK() OVER (PARTITION BY COALESCE(c.total_web_sales, 0) >= COALESCE(c.total_catalog_sales, 0) ORDER BY COALESCE(c.total_web_sales, 0) DESC) AS sales_rank
    FROM CustomerSales c
),
CombinedReturns AS (
    SELECT 
        COALESCE(sr_returning_customer_sk, wr_returning_customer_sk) AS customer_sk,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr ON sr.sr_returning_customer_sk = wr.wr_returning_customer_sk
    GROUP BY customer_sk
)
SELECT CASE 
           WHEN s.total_web_sales > s.total_catalog_sales THEN 'More Web Sales'
           WHEN s.total_web_sales < s.total_catalog_sales THEN 'More Catalog Sales'
           ELSE 'Equal Sales'
       END AS sales_comparison,
       r.total_returns,
       s.customer_id,
       s.sales_rank
FROM SalesWithRanks s
LEFT JOIN CombinedReturns r ON s.customer_id = r.customer_sk
WHERE r.total_returns IS NOT NULL AND r.total_returns > 0
ORDER BY s.sales_rank, r.total_returns DESC;
