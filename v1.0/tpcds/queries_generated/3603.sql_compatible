
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE cr.total_returns > 5
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales
    JOIN store s ON store_sales.ss_store_sk = s.s_store_sk
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy BETWEEN 6 AND 8
    )
    GROUP BY s.s_store_sk, s.s_store_name
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    s.s_store_name,
    tr.total_returns,
    tr.total_return_amount,
    tr.avg_return_quantity,
    COALESCE(total_sales, 0) AS store_sales
FROM HighReturnCustomers tr
LEFT JOIN TopStores s ON s.s_store_sk IN (
    SELECT ss_store_sk 
    FROM store_sales 
    WHERE ss_customer_sk = tr.sr_customer_sk
)
ORDER BY tr.total_return_amount DESC, store_sales DESC;
