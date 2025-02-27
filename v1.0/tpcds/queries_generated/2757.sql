
WITH SalesData AS (
    SELECT
        ws.bill_customer_sk,
        ws.ship_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid) DESC) AS order_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_marital_status = 'M' AND
        cd.cd_gender = 'F' AND
        ws.sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY
        ws.bill_customer_sk, ws.ship_customer_sk
),
TopCustomers AS (
    SELECT
        bill_customer_sk,
        ship_customer_sk,
        total_sales,
        total_orders
    FROM
        SalesData
    WHERE
        order_rank <= 10
)
SELECT
    cu.c_first_name || ' ' || cu.c_last_name AS customer_name,
    SUM(ts.total_sales) AS total_sales,
    SUM(ts.total_orders) AS total_orders,
    AVG(ts.total_sales) AS avg_sales_per_order,
    COUNT(DISTINCT wp.web_page_id) AS unique_pages_visited
FROM
    TopCustomers ts
JOIN
    customer cu ON ts.bill_customer_sk = cu.c_customer_sk
LEFT JOIN
    web_page wp ON wp.wp_customer_sk = ts.bill_customer_sk
GROUP BY
    cu.c_first_name, cu.c_last_name
HAVING
    SUM(ts.total_sales) > 5000
ORDER BY
    total_sales DESC;
