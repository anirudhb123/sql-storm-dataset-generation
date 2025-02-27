
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(coalesce(sr_return_quantity, 0) + coalesce(cr_return_quantity, 0)) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr_order_number) AS catalog_return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_id
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
SalesStatistics AS (
    SELECT 
        d_year,
        d_month_seq,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM MonthlySales
),
TopReturningCustomers AS (
    SELECT 
        cr.c_customer_id,
        cr.total_returned,
        s.total_sales,
        s.sales_rank
    FROM CustomerReturns cr
    JOIN SalesStatistics s ON s.total_sales > 10000
    WHERE cr.total_returned > 5
)
SELECT 
    tr.c_customer_id,
    tr.total_returned,
    tr.total_sales,
    CASE 
        WHEN tr.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers'
    END AS customer_category
FROM TopReturningCustomers tr
ORDER BY tr.total_sales DESC, tr.total_returned DESC;
