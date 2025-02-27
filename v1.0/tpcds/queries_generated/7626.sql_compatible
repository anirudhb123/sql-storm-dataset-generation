
WITH customer_totals AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        ct.c_customer_sk, 
        rt.total_sales,
        rt.total_orders,
        rt.total_returns,
        RANK() OVER (ORDER BY rt.total_sales DESC) AS sales_rank
    FROM customer_totals rt
),
sales_summary AS (
    SELECT 
        d.d_year,
        AVG(tc.total_sales) AS avg_total_sales,
        SUM(tc.total_orders) AS total_orders,
        SUM(tc.total_returns) AS total_returns
    FROM top_customers tc
    JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
    JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    WHERE tc.sales_rank <= 100
    GROUP BY d.d_year
)
SELECT 
    d.d_year,
    COALESCE(ss.avg_total_sales, 0) AS avg_total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_returns, 0) AS total_returns,
    w.w_warehouse_name
FROM date_dim d
LEFT JOIN sales_summary ss ON d.d_year = ss.d_year
CROSS JOIN warehouse w
WHERE d.d_year BETWEEN 2020 AND 2023
ORDER BY d.d_year, w.w_warehouse_name;
