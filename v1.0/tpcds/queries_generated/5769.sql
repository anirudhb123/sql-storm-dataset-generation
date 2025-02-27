
WITH customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2022 AND d.d_month_seq BETWEEN 1 AND 3
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_sales,
           DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
average_sales AS (
    SELECT AVG(total_sales) AS avg_sales
    FROM customer_sales
)
SELECT tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_sales, as.avg_sales
FROM top_customers tc, average_sales as
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
