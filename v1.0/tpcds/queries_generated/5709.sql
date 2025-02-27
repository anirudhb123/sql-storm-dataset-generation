
WITH SalesSummary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value,
        DENSE_RANK() OVER (PARTITION BY c.c_country ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        customer AS c
    JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        c.c_customer_id, c.c_country
),
TopCustomers AS (
    SELECT
        s.c_customer_id,
        s.total_sales,
        s.order_count,
        s.avg_order_value,
        s.sales_rank
    FROM
        SalesSummary s
    WHERE
        s.sales_rank <= 10
)
SELECT
    t.c_customer_id,
    t.total_sales,
    t.order_count,
    t.avg_order_value,
    d.d_year,
    d.d_month_name
FROM
    TopCustomers t
JOIN
    date_dim d ON d.d_date_sk IN (
        SELECT
            ws.ws_sold_date_sk
        FROM
            web_sales ws
        WHERE
            ws.ws_ship_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_customer_id = t.c_customer_id)
        GROUP BY
            ws.ws_sold_date_sk
    )
ORDER BY
    t.total_sales DESC;
