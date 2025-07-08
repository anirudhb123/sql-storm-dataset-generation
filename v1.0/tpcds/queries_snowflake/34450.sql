WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 0 AS Level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.Level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.Level < 3
),
SalesData AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_by_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date_id, d.d_year
),
HighProfitSales AS (
    SELECT d.d_year, d.d_month_seq, sd.total_profit, sd.total_orders
    FROM date_dim d
    JOIN SalesData sd ON d.d_date_id = sd.d_date_id
    WHERE sd.rank_by_profit <= 10
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.Level,
    hps.d_year,
    hps.d_month_seq,
    hps.total_profit,
    hps.total_orders,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'XX') AS state,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_store_sk IN (SELECT sr_store_sk FROM store_returns WHERE sr_customer_sk = ch.c_customer_sk)) AS return_count
FROM CustomerHierarchy ch
LEFT JOIN customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
JOIN HighProfitSales hps ON hps.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
WHERE ch.Level = 0
ORDER BY hps.total_profit DESC, ch.c_last_name;