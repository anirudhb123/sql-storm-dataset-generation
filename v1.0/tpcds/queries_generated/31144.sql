
WITH RECURSIVE SalesCTE AS (
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    UNION ALL
    SELECT ss.sold_date_sk, ss.item_sk, ss.quantity, ss.net_paid, cte.level + 1
    FROM store_sales ss
    INNER JOIN SalesCTE cte ON ss_sold_date_sk = cte.ss_sold_date_sk - 1 AND ss_item_sk = cte.ss_item_sk
    WHERE cte.level < 5
),
TotalSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT customer_id, total_net_paid, transaction_count,
           RANK() OVER (ORDER BY total_net_paid DESC) AS rank
    FROM TotalSales
    WHERE total_net_paid IS NOT NULL
)
SELECT 
    tc.customer_id,
    tc.total_net_paid,
    tc.transaction_count,
    COALESCE(ca.ca_city, 'Unknown') AS address_city,
    DENSE_RANK() OVER (PARTITION BY tc.transaction_count ORDER BY tc.total_net_paid DESC) as sales_rank,
    CASE
        WHEN tc.total_net_paid > 1000 THEN 'High Value'
        WHEN tc.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM TopCustomers tc
LEFT JOIN customer_address ca ON (tc.customer_id = ca.ca_address_id)
WHERE tc.rank <= 100
ORDER BY tc.total_net_paid DESC
LIMIT 50;
