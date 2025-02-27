
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           c_current_cdemo_sk, 
           0 AS hierarchy_level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
  UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 
           ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
AggregatedSales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesPerformance AS (
    SELECT 
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ag.total_sales, 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(ag.total_sales, 0) DESC) AS sales_rank,
        CASE 
            WHEN ag.total_sales > 1000 THEN 'High'
            WHEN ag.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        ch.c_customer_sk
    FROM CustomerHierarchy ch
    LEFT JOIN AggregatedSales ag ON ch.c_customer_sk = ag.ws_bill_customer_sk
),
RecentReturns AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_amount) AS total_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2002-10-01')
    GROUP BY cr_returning_customer_sk
)
SELECT 
    sp.c_first_name,
    sp.c_last_name,
    sp.total_sales,
    sp.sales_rank,
    sp.sales_category,
    COALESCE(rr.total_returns, 0) AS total_returns,
    (sp.total_sales - COALESCE(rr.total_returns, 0)) AS net_sales
FROM SalesPerformance sp
LEFT JOIN RecentReturns rr ON sp.c_customer_sk = rr.cr_returning_customer_sk
WHERE sp.sales_category IN ('High', 'Medium')
ORDER BY net_sales DESC, sp.sales_rank;
