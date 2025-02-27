
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 8 LIMIT 1)
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    tc.total_sales,
    tc.order_count,
    tc.avg_order_value,
    d.d_date AS sales_date
FROM
    TopCustomers tc
JOIN
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
