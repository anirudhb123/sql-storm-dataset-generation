
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_birth_month, c.c_birth_year,
           CASE 
               WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_first_name 
               ELSE 'Mr. ' || c.c_first_name 
           END AS full_name,
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_birth_month, c.c_birth_year,
           ch.full_name || ' (linked)',
           level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 2
),
AggregatedPurchases AS (
    SELECT c.c_customer_sk,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
TopSpenders AS (
    SELECT c.c_customer_sk, 
           c.full_name,
           ap.total_orders,
           ap.total_spent,
           ROW_NUMBER() OVER (ORDER BY ap.total_spent DESC) AS rank
    FROM CustomerHierarchy c
    JOIN AggregatedPurchases ap ON c.c_customer_sk = ap.c_customer_sk
)
SELECT th.full_name, 
       th.total_orders, 
       th.total_spent, 
       CASE 
           WHEN th.rank <= 10 THEN 'Top 10'
           WHEN th.total_spent IS NULL THEN 'No Purchases'
           ELSE 'Others'
       END AS spending_category
FROM TopSpenders th
WHERE (th.total_orders > 10 OR th.rank <= 10)
ORDER BY th.total_spent DESC NULLS LAST;
