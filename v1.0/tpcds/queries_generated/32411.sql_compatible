
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_month, c_birth_year,
           CONCAT(c_first_name, ' ', c_last_name) AS full_name,
           1 AS level
    FROM customer
    WHERE c_birth_month IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year,
           CONCAT(ch.full_name, ' -> ', c.c_first_name, ' ', c.c_last_name) AS full_name,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
    WHERE ch.level < 5
),
AggregatedSales AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_spent,
           COUNT(ws_order_number) AS order_count,
           RANK() OVER (PARTITION BY c_birth_month, c_birth_year ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank_by_spending
    FROM web_sales
    INNER JOIN customer c ON ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ws_bill_customer_sk, c_birth_month, c_birth_year
),
SalesLeaderboard AS (
    SELECT ch.c_customer_sk, ch.full_name, a.total_spent, a.order_count,
           DENSE_RANK() OVER (ORDER BY a.total_spent DESC) AS spending_rank
    FROM CustomerHierarchy ch
    LEFT JOIN AggregatedSales a ON ch.c_customer_sk = a.customer_sk
)
SELECT ch.full_name, ch.level, COALESCE(a.order_count, 0) AS order_count,
       COALESCE(a.total_spent, 0.00) AS total_spent, sl.spending_rank
FROM CustomerHierarchy ch
LEFT JOIN AggregatedSales a ON ch.c_customer_sk = a.customer_sk
LEFT JOIN SalesLeaderboard sl ON ch.c_customer_sk = sl.c_customer_sk
WHERE ch.level = 1 AND (a.total_spent IS NULL OR a.total_spent > 1000)
ORDER BY sl.spending_rank, ch.full_name;
