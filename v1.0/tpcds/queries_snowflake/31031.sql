
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk, s_store_name, s_number_employees, s_floor_space, 
           CAST(NULL AS VARCHAR(255)) AS parent_store, 1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, s.s_number_employees, s.s_floor_space,
           sh.s_store_name AS parent_store, sh.level + 1
    FROM store s
    JOIN SalesHierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE sh.level < 3
), SalesData AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(*) AS sales_count,
        s.s_store_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, s.s_store_name
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), CombinedData AS (
    SELECT
        COALESCE(c.c_customer_sk, -1) AS customer_id,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(cs.total_orders, 0) AS total_orders,
        CASE WHEN cs.total_spent > 1000 THEN 'High' 
             WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium' 
             ELSE 'Low' END AS spending_category
    FROM SalesData sd
    FULL OUTER JOIN CustomerStats cs ON sd.ss_item_sk = cs.c_customer_sk
    LEFT JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    CONCAT('Customer ID: ', CAST(customer_id AS VARCHAR(255)), 
           ' - Total Sales: ', CAST(total_sales AS VARCHAR(255)),
           ' - Total Orders: ', CAST(total_orders AS VARCHAR(255)), 
           ' - Spending Category: ', spending_category) AS Report
FROM CombinedData
WHERE total_sales > 0
ORDER BY total_sales DESC
LIMIT 10;
