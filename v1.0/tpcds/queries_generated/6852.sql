
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
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
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_profit,
    t.order_count
FROM
    TopCustomers t
WHERE
    t.rank <= 10
ORDER BY
    t.total_profit DESC;

WITH MonthlySales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
),
YearlySales AS (
    SELECT
        ms.d_year,
        SUM(ms.total_sales) AS annual_sales
    FROM
        MonthlySales ms
    GROUP BY
        ms.d_year
)
SELECT
    ys.d_year,
    ys.annual_sales,
    CASE
        WHEN ys.annual_sales > 100000 THEN 'High'
        WHEN ys.annual_sales > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    YearlySales ys
ORDER BY
    ys.d_year;
