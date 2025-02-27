
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT DMIN.d_date_sk FROM date_dim DMIN WHERE DMIN.d_date = '2023-01-01')
        AND (SELECT DMAX.d_date_sk FROM date_dim DMAX WHERE DMAX.d_date = '2023-12-31')
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
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    (SELECT COUNT(DISTINCT sr.returned_date_sk) FROM store_returns sr WHERE sr.sr_customer_sk = tc.c_customer_sk) AS returns_count,
    (SELECT AVG(ws_net_profit) FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk) AS avg_net_profit
FROM
    TopCustomers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
