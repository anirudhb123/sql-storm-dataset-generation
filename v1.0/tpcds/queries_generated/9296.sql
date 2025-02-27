
WITH SalesStats AS (
    SELECT
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_ship_date_sk) AS distinct_ship_dates
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c_customer_id,
        total_sales,
        avg_profit,
        order_count,
        distinct_ship_dates,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        SalesStats
)
SELECT
    tc.c_customer_id,
    tc.total_sales,
    tc.avg_profit,
    tc.order_count,
    tc.distinct_ship_dates,
    d.d_month_name AS sales_month
FROM
    TopCustomers tc
JOIN
    date_dim d ON d.d_year = 2023
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
