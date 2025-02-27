
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
DailySales AS (
    SELECT d.d_date, 
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
TopCustomers AS (
    SELECT cd.cd_demo_sk, 
           SUM(ws.ws_net_paid) AS total_spent,
           RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS customer_rank
    FROM customer_demographics cd
    JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk
    HAVING SUM(ws.ws_net_paid) > 1000
),
ReturnedItems AS (
    SELECT sr_item_sk,
           COUNT(*) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.level,
    ds.total_sales,
    ds.total_orders,
    tc.total_spent,
    ri.total_returns,
    ri.total_return_amount
FROM CustomerHierarchy ch
JOIN DailySales ds ON ds.d_date = CURRENT_DATE
LEFT JOIN TopCustomers tc ON tc.cd_demo_sk = ch.c_current_cdemo_sk
LEFT JOIN ReturnedItems ri ON ri.sr_item_sk = ch.c_customer_sk 
WHERE ch.level < 3
ORDER BY tc.total_spent DESC NULLS LAST, ds.total_sales DESC;
