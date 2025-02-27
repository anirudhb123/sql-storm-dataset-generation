
WITH RECURSIVE SalesCTE AS (
    SELECT s.s_store_sk, 
           SUM(ss.ss_sales_price) AS total_sales,
           COUNT(ss.ss_ticket_number) AS total_transactions,
           ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 
          (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) - 30 AND 
          (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY s.s_store_sk
),
CustomerReturns AS (
    SELECT cr.returning_customer_sk, 
           SUM(cr.cr_return_amount) AS total_returns,
           COUNT(cr.cr_order_number) AS total_returned_items
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
MaxReturnCustomer AS (
    SELECT cr.returning_customer_sk,
           cr.total_returns,
           ROW_NUMBER() OVER (ORDER BY cr.total_returns DESC) AS return_rank
    FROM CustomerReturns cr
)
SELECT s.s_store_name,
       c.c_first_name,
       c.c_last_name,
       COALESCE(sales.total_sales, 0) AS total_sales,
       COALESCE(returns.total_returns, 0) AS total_returns,
       (COALESCE(sales.total_sales, 0) - COALESCE(returns.total_returns, 0)) AS net_sales
FROM store s
LEFT JOIN SalesCTE sales ON s.s_store_sk = sales.s_store_sk
LEFT JOIN MaxReturnCustomer returns ON returns.returning_customer_sk = (SELECT TOP 1 c_customer_sk FROM customer WHERE c_customer_sk IS NOT NULL ORDER BY NEWID())
JOIN customer c ON c.c_customer_sk = returns.returning_customer_sk
WHERE sales.sales_rank = 1 OR returns.return_rank = 1
ORDER BY net_sales DESC;
