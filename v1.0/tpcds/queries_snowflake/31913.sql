
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
),
FilteredStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        CASE 
            WHEN s_number_employees IS NULL THEN 0 
            ELSE s_number_employees 
        END AS employees,
        DENSE_RANK() OVER (ORDER BY s_floor_space DESC) AS store_rank
    FROM store
    WHERE s_closed_date_sk IS NULL
)
SELECT 
    tc.full_name,
    tc.total_sales,
    fs.s_store_name,
    fs.employees
FROM TopCustomers tc
LEFT JOIN FilteredStores fs ON fs.store_rank < 10
WHERE tc.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
AND tc.rank <= 100
ORDER BY tc.total_sales DESC;
