
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
), CustomerRanking AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerSales
), HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.rank
    FROM CustomerRanking r
    JOIN customer c ON r.c_customer_id = c.c_customer_id
    WHERE r.rank <= 10
)
SELECT
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    CASE 
        WHEN hvc.rank <= 5 THEN 'Top 5 Customers'
        ELSE 'Customers 6-10'
    END AS customer_category,
    COALESCE(ROUND(SUM(ws.ws_net_paid) / NULLIF(NULLIF(hvc.rank, 0), 0), 2), 0) AS avg_spent_per_order
FROM HighValueCustomers hvc
LEFT JOIN web_sales ws ON hvc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY hvc.c_customer_id, hvc.c_first_name, hvc.c_last_name, hvc.rank
ORDER BY hvc.rank;
