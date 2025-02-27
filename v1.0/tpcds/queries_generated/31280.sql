
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           0 AS level
    FROM customer c
    WHERE c.c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 10  -- limiting the recursion depth for safety
),
SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY w.warehouse_id
),
BestCustomers AS (
    SELECT 
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name,
        SUM(s.ws_net_profit) AS total_spent,
        RANK() OVER (ORDER BY SUM(s.ws_net_profit) DESC) AS rank
    FROM CustomerHierarchy h
    LEFT JOIN web_sales s ON h.c_customer_sk = s.ws_ship_customer_sk
    GROUP BY h.c_customer_sk, h.c_first_name, h.c_last_name
),
TopStores AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
),
FinalReport AS (
    SELECT 
        bc.c_first_name,
        bc.c_last_name,
        bc.total_spent,
        ts.s_store_id,
        ts.store_profit,
        sd.total_net_profit,
        CASE 
            WHEN bc.rank <= 10 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_status
    FROM BestCustomers bc
    JOIN TopStores ts ON ts.store_profit > 1000
    CROSS JOIN SalesData sd
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_spent,
    fr.s_store_id,
    fr.store_profit,
    fr.total_net_profit,
    COALESCE(fr.total_net_profit, 0) AS net_profit_adjusted,
    CONCAT(fr.c_first_name, ' ', fr.c_last_name) AS full_name,
    CASE
        WHEN fr.total_spent IS NULL THEN 'No Purchases Yet'
        ELSE 'Purchases Made'
    END AS purchase_status
FROM FinalReport fr
WHERE fr.total_spent > 500
ORDER BY fr.total_spent DESC;
