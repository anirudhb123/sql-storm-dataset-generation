
WITH RECURSIVE CustomerSales AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT
        cs.c_customer_sk,
        cs.customer_name,
        cs.total_sales + COALESCE(SUM(cs2.ws_ext_sales_price), 0) AS total_sales,
        cs.total_orders + COUNT(cs2.ws_order_number) AS total_orders
    FROM
        CustomerSales cs
    JOIN
        web_sales cs2 ON cs.c_customer_sk = cs2.ws_bill_customer_sk
    WHERE
        cs.total_orders < 10
    GROUP BY
        cs.c_customer_sk, cs.customer_name, cs.total_sales, cs.total_orders
),
RankedSales AS (
    SELECT
        c.c_customer_sk,
        c.customer_name,
        c.total_sales,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM
        CustomerSales c
)
SELECT
    r.customer_name,
    r.total_sales,
    r.sales_rank,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_ext_sales_price) OVER (PARTITION BY d.d_year ORDER BY r.sales_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS annual_sales_sum,
    COUNT(ws.ws_order_number) OVER (PARTITION BY d.d_year ORDER BY r.sales_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS order_count
FROM
    RankedSales r
LEFT JOIN
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= DATE '2002-10-01')
LEFT JOIN
    web_sales ws ON r.c_customer_sk = ws.ws_bill_customer_sk
WHERE
    r.sales_rank <= 10
ORDER BY
    r.sales_rank;
