
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
    UNION ALL
    SELECT 
        d_year - 1,
        total_net_profit * 1.1,
        RANK() OVER (ORDER BY total_net_profit * 1.1 DESC)
    FROM SalesGrowth
    WHERE d_year > (SELECT MIN(d_year) FROM date_dim)
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_spent IS NOT NULL
),
StoreShipModes AS (
    SELECT 
        s.s_store_name,
        sm.sm_type,
        COUNT(ws_order_number) AS total_orders
    FROM store s
    LEFT JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY s.s_store_name, sm.sm_type
)
SELECT 
    t.d_year,
    tg.profit_rank,
    tc.c_customer_id,
    tc.order_count,
    tc.total_spent,
    s.s_store_name,
    ss.sm_type AS store_shipping_method,
    ssm.total_orders,
    CASE 
        WHEN gs.total_net_profit IS NULL THEN 'No Growth'
        WHEN gs.total_net_profit > 0 THEN 'Positive Growth'
        ELSE 'Negative Growth'
    END AS growth_status
FROM SalesGrowth gs
FULL OUTER JOIN TopCustomers tc ON tc.spending_rank <= 10
FULL OUTER JOIN StoreShipModes ssm ON ssm.total_orders > 0
JOIN date_dim t ON t.d_year = gs.d_year
JOIN store s ON s.s_store_sk = tc.order_count % 10  -- Arbitrary adjustment to join stores
ORDER BY t.d_year DESC, tc.total_spent DESC;
