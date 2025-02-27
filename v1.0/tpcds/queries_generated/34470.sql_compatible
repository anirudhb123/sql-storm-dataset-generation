
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS depth
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.depth + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        AVG(ws_net_paid_inc_tax) AS avg_spent,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rnk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ss.total_orders,
        ss.total_spent,
        ss.avg_spent
    FROM CustomerHierarchy ch
    JOIN SalesSummary ss ON ch.c_customer_sk = ss.customer_sk
    WHERE ss.total_spent > (SELECT AVG(total_spent) FROM SalesSummary)
      AND ss.rnk <= 10
)
SELECT 
    c.c_customer_id,
    a.ca_city,
    a.ca_state,
    hv.total_orders,
    hv.total_spent 
FROM HighValueCustomers hv
JOIN customer c ON hv.c_customer_sk = c.c_customer_sk
JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN (
    SELECT 
        c_customer_sk,
        COUNT(*) AS return_count,
        COALESCE(SUM(sr_return_amt + sr_return_tax), 0) AS total_return_amt
    FROM store_returns sr
    GROUP BY c_customer_sk
) r ON hv.c_customer_sk = r.c_customer_sk
WHERE hv.total_orders > 5
  AND a.ca_state IS NOT NULL
ORDER BY hv.total_spent DESC, hv.total_orders DESC;
