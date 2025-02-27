
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    d.d_date,
    d.d_month_seq,
    d.d_year
FROM
    TopCustomers tc
JOIN
    date_dim d ON d.d_date_sk = (
        SELECT MAX(ws.ws_ship_date_sk)
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
    )
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
