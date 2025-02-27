
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (4, 5) 
    )
    GROUP BY ws_bill_customer_sk
), 
ReturnSummary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    WHERE wr_returned_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy IN (4, 5)
    )
    GROUP BY wr_returning_customer_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN ss.total_sales IS NOT NULL AND rs.total_return_amount IS NOT NULL 
        THEN ss.total_sales - rs.total_return_amount 
        ELSE ss.total_sales 
    END AS net_sales,
    ch.level
FROM CustomerHierarchy ch
LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN ReturnSummary rs ON ch.c_customer_sk = rs.wr_returning_customer_sk
WHERE ch.level < 3
ORDER BY net_sales DESC, ch.c_last_name, ch.c_first_name;
