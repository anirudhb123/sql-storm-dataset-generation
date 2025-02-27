
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT
        w.ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY w.ws_sold_date_sk
),
AggregateSales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.total_profit,
        sd.total_orders,
        sd.unique_customers,
        DENSE_RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM SalesData sd
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(a.total_profit, 0) AS total_profit,
    COALESCE(a.total_orders, 0) AS total_orders,
    COALESCE(a.unique_customers, 0) AS unique_customers,
    CASE 
        WHEN a.profit_rank IS NULL THEN 'No Sales'
        WHEN a.profit_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM CustomerHierarchy ch
LEFT JOIN AggregateSales a ON ch.c_current_cdemo_sk = a.ws_sold_date_sk 
WHERE ch.level <= 3
ORDER BY ch.c_customer_sk;
