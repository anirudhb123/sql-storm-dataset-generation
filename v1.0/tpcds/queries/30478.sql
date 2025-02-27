
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS hierarchy_level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.hierarchy_level < 5
),
SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_list_price) AS avg_list_price
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_credit_rating ORDER BY SUM(COALESCE(ws.ws_net_profit, 0)) DESC) AS rank
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating
    HAVING SUM(COALESCE(ws.ws_net_profit, 0)) > 1000
)
SELECT 
    wh.w_warehouse_id, 
    sd.total_profit,
    sd.order_count,
    sd.avg_list_price,
    hvc.full_name AS high_value_customer,
    hvc.cd_credit_rating
FROM SalesData sd
JOIN warehouse wh ON sd.w_warehouse_id = wh.w_warehouse_id
LEFT JOIN HighValueCustomers hvc ON sd.total_profit > 5000
ORDER BY sd.total_profit DESC, hvc.rank
FETCH FIRST 10 ROWS ONLY;
