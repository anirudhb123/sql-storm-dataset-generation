
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
DemographicStats AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(cs.total_sales) AS avg_sales,
        SUM(cs.total_transactions) AS total_transactions
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
),
DateStats AS (
    SELECT
        dd.d_year,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY
        dd.d_year
)
SELECT
    ds.d_year,
    ds.total_web_sales,
    ds.total_web_orders,
    ds.total_web_sales / NULLIF(ds.total_web_orders, 0) AS avg_web_sales_per_order,
    ds.total_web_orders / NULLIF(ds.total_web_sales, 0) AS avg_orders_per_dollar,
    ds.total_web_sales / (SELECT SUM(customer_count) FROM DemographicStats) AS sales_per_demographic
FROM
    DateStats ds
ORDER BY
    ds.d_year DESC;
