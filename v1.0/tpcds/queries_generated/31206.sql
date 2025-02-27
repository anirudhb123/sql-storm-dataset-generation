
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS Rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk > 20000
    UNION ALL
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.c_birth_month,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS Rank
    FROM
        SalesHierarchy sh
    JOIN
        web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_quantity > 10
),
AggregateSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        as.total_spent,
        RANK() OVER (ORDER BY as.total_spent DESC) AS spending_rank
    FROM
        customer c
    JOIN
        AggregateSales as ON c.c_customer_sk = as.c_customer_sk
    WHERE
        as.total_spent IS NOT NULL
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    CASE 
        WHEN tc.spending_rank <= 10 THEN 'Top 10 Customers'
        WHEN tc.spending_rank <= 50 THEN 'Top 50 Customers'
        ELSE 'Regular Customers'
    END AS customer_category,
    sh.ws_sales_price,
    sh.ws_quantity
FROM
    TopCustomers tc
LEFT JOIN
    SalesHierarchy sh ON tc.c_customer_sk = sh.c_customer_sk
WHERE
    sh.Rank <= 5 OR sh.Rank IS NULL
ORDER BY
    tc.spending_rank, tc.c_last_name, tc.c_first_name;
