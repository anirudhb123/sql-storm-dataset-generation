
WITH SalesData AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        EXTRACT(YEAR FROM dd.d_date) AS sales_year,
        dd.d_month AS sales_month
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_date BETWEEN '2022-01-01' AND '2022-12-31'
        AND cd.cd_gender = 'F'
    GROUP BY
        c.c_customer_id, sales_year, sales_month
),

MonthlyStats AS (
    SELECT
        sales_year,
        sales_month,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(total_profit) AS total_profit,
        AVG(avg_order_value) AS avg_order_value
    FROM
        SalesData
    GROUP BY
        sales_year, sales_month
)

SELECT
    sales_year,
    sales_month,
    unique_customers,
    total_profit,
    avg_order_value
FROM
    MonthlyStats
ORDER BY
    sales_year, sales_month;
