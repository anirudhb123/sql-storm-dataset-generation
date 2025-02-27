
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.total_orders,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS revenue_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
ReturnStatistics AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS returns_count,
        SUM(sr_return_amt) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY sr_customer_sk
),
CombinedStats AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent,
        tc.total_orders,
        tc.avg_order_value,
        COALESCE(rs.returns_count, 0) AS returns_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (tc.total_spent - COALESCE(rs.total_returns, 0)) AS net_spending
    FROM TopCustomers tc
    LEFT JOIN ReturnStatistics rs ON tc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.total_orders,
    cs.avg_order_value,
    cs.returns_count,
    cs.total_returns,
    cs.net_spending
FROM CombinedStats cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE cs.revenue_rank <= 10
ORDER BY cs.net_spending DESC
