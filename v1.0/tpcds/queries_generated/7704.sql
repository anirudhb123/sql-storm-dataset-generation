
WITH SalesSummary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        customer AS c
    JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM
        SalesSummary s
    JOIN
        customer AS c ON s.c_customer_id = c.c_customer_id
    WHERE
        s.sales_rank <= 10
)
SELECT
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    a.ca_city,
    a.ca_state
FROM
    TopCustomers tc
JOIN
    customer_demographics AS cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN
    customer_address AS a ON tc.c_customer_id = a.ca_address_id
ORDER BY
    tc.total_sales DESC;
