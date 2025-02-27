
WITH CustomerPurchaseSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ss.ss_net_paid) AS total_spent,
        MAX(d.d_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk OR ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk
),
AverageSpending AS (
    SELECT 
        AVG(total_spent) AS avg_spent
    FROM CustomerPurchaseSummary
),
TopCustomers AS (
    SELECT 
        cus.c_customer_sk,
        cus.total_orders,
        cus.total_spent,
        cus.last_purchase_date
    FROM CustomerPurchaseSummary cus
    INNER JOIN AverageSpending avg ON cus.total_spent > avg.avg_spent
    ORDER BY cus.total_spent DESC
    LIMIT 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cus.total_orders,
    cus.total_spent,
    cus.last_purchase_date
FROM TopCustomers cus
JOIN customer c ON cus.c_customer_sk = c.c_customer_sk;
