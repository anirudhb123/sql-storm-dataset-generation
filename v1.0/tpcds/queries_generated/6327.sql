
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.customer_id,
        c.total_sales,
        c.total_orders,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM
        CustomerSales c
),
SalesSummary AS (
    SELECT
        t.sales_rank,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS sales_sum,
        AVG(total_sales) AS average_sales
    FROM
        TopCustomers t
    GROUP BY
        t.sales_rank
)
SELECT
    t.sales_rank,
    t.customer_count,
    t.sales_sum,
    t.average_sales,
    r.r_reason_desc
FROM
    SalesSummary t
LEFT JOIN
    reason r ON r.r_reason_sk = (SELECT MIN(r_reason_sk) FROM reason) -- Just to ensure place-holding for the purpose
WHERE
    t.sales_rank <= 10 -- Top 10 customers
ORDER BY
    t.sales_rank;
