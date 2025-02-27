
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_store_sk
    UNION ALL
    SELECT 
        ss_store_sk,
        total_sales * 0.9 AS total_sales,
        sales_rank + 1
    FROM SalesCTE
    WHERE sales_rank < 3
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(COUNT(DISTINCT ss_ticket_number), 0) AS return_count,
        SUM(COALESCE(ss_ext_sales_price, 0)) AS total_ext_sales,
        cd.gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, cd.gender, cd_marital_status
    HAVING SUM(COALESCE(ss_ext_sales_price, 0)) > 1000
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.total_ext_sales,
        c.return_count,
        ROW_NUMBER() OVER (ORDER BY c.total_ext_sales DESC) AS rank
    FROM CustomerInfo c
    WHERE return_count > 1
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    s.store_name,
    t.sales_rank,
    tc.rank AS customer_rank,
    tc.total_ext_sales,
    CASE 
        WHEN tc.total_ext_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM warehouse w
JOIN store s ON w.w_warehouse_sk = s.s_warehouse_sk
LEFT JOIN SalesCTE t ON w.w_warehouse_sk = t.ss_store_sk
LEFT JOIN TopCustomers tc ON s.s_store_sk = tc.customer_sk
WHERE t.total_sales > 5000 OR tc.total_ext_sales IS NOT NULL
ORDER BY t.sales_rank, tc.rank;
