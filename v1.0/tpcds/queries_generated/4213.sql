
WITH RankedStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_sales_count,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY s_number_employees DESC) AS rn
    FROM (
        SELECT 
            s_store_sk, 
            s_store_name, 
            s_number_employees,
            COUNT(ss_ticket_number) AS s_sales_count
        FROM store 
        LEFT JOIN store_sales ON s_store_sk = ss_store_sk
        GROUP BY s_store_sk, s_store_name, s_number_employees
    ) AS StoreSales
), CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_qty) AS total_return_qty,
        AVG(sr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS returns_count
    FROM store_returns
    GROUP BY sr_customer_sk
), TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_state,
        cr.total_return_qty,
        cr.avg_return_amount,
        cr.returns_count,
        DENSE_RANK() OVER (ORDER BY cr.total_return_qty DESC) AS customer_rank
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_return_qty > 0
), ReturnAnalysis AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        s.s_store_name,
        s.s_number_employees,
        tc.total_return_qty,
        tc.avg_return_amount,
        rs.s_sales_count
    FROM TopCustomers tc
    LEFT JOIN RankedStores rs ON tc.c_state = rs.s_code
    JOIN store s ON rs.s_store_sk = s.s_store_sk
    WHERE rs.rn <= 3 AND tc.returns_count > 1
)
SELECT 
    ra.c_first_name,
    ra.c_last_name,
    ra.s_store_name,
    COALESCE(ra.s_sales_count, 0) AS s_sales_count,
    ra.total_return_qty,
    ra.avg_return_amount,
    CASE 
        WHEN ra.avg_return_amount IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM ReturnAnalysis ra
WHERE ra.s_sales_count > 100
ORDER BY ra.total_return_qty DESC, ra.c_last_name ASC;
