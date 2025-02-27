
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_quarter_seq
    FROM date_dim
    WHERE d_date >= '2020-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq, d.d_quarter_seq
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk + 1
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(cs.cs_item_sk) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY c.c_customer_sk
),
WarehouseStats AS (
    SELECT
        w.w_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_paid) AS total_web_revenue
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerStats cs
    WHERE cs.total_sales > 0
),
TopWarehouses AS (
    SELECT
        ws.w_warehouse_sk,
        ws.total_web_orders,
        ws.total_web_revenue,
        DENSE_RANK() OVER (ORDER BY ws.total_web_revenue DESC) AS revenue_rank
    FROM WarehouseStats ws
    WHERE ws.total_web_orders > 0
)
SELECT
    tc.c_customer_sk,
    tc.total_sales,
    tc.total_profit,
    tw.w_warehouse_sk,
    tw.total_web_orders,
    tw.total_web_revenue
FROM TopCustomers tc
FULL OUTER JOIN TopWarehouses tw ON tc.c_customer_sk = tw.w_warehouse_sk
WHERE (tc.profit_rank <= 10 OR tw.revenue_rank <= 10)
ORDER BY COALESCE(tc.total_profit, 0) DESC, COALESCE(tw.total_web_revenue, 0) DESC;
