
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_sk
),
TopWebSites AS (
    SELECT
        web_site_sk,
        total_sales,
        total_orders
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_customer_spent,
        COUNT(ws.ws_order_number) AS total_customer_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (
            SELECT MIN(dd.d_date_sk)
            FROM date_dim dd WHERE dd.d_year = 2023
        ) AND (
            SELECT MAX(dd.d_date_sk)
            FROM date_dim dd WHERE dd.d_year = 2023
        )
    GROUP BY
        c.c_customer_sk
)
SELECT
    T.web_site_sk,
    T.total_sales,
    T.total_orders,
    C.total_customer_spent,
    C.total_customer_orders
FROM
    TopWebSites T
LEFT JOIN
    CustomerStats C ON T.web_site_sk = C.total_customer_spent
ORDER BY
    T.total_sales DESC;
