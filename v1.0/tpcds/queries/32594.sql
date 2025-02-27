
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_first_name IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_hdemo_sk
    WHERE ch.level < 5
),
DateRange AS (
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    WHERE d.d_date >= '2022-01-01' AND d.d_date <= '2022-12-31'
),
SalesAggregates AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(*) AS total_orders,
           RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           sa.total_sales,
           sa.total_orders
    FROM SalesAggregates sa
    JOIN customer c ON sa.ws_bill_customer_sk = c.c_customer_sk
    WHERE sa.sales_rank <= 10
)
SELECT ch.c_customer_id,
       ch.cd_gender,
       ch.cd_marital_status,
       COALESCE(tc.total_sales, 0) AS total_sales,
       COALESCE(tc.total_orders, 0) AS total_orders,
       COUNT(DISTINCT dr.d_date_sk) AS active_days
FROM CustomerHierarchy ch
LEFT JOIN TopCustomers tc ON ch.c_customer_sk = tc.c_customer_sk
JOIN DateRange dr ON tc.total_sales > 0
GROUP BY ch.c_customer_id, ch.cd_gender, ch.cd_marital_status, tc.total_sales, tc.total_orders
HAVING COUNT(DISTINCT dr.d_date_sk) > 5
ORDER BY total_sales DESC, ch.c_customer_id;
