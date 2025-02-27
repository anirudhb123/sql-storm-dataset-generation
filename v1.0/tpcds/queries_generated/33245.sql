
WITH RECURSIVE sales_summary AS (
    SELECT
        w.warehouse_sk,
        w.warehouse_name,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM
        warehouse w
    LEFT JOIN
        web_sales ws ON w.warehouse_sk = ws.warehouse_sk
    GROUP BY
        w.warehouse_sk, w.warehouse_name
),
high_value_customers AS (
    SELECT
        c.customer_sk,
        c.customer_id,
        cd.credit_rating,
        SUM(ws.ext_sales_price) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.customer_sk = ws.bill_customer_sk
    JOIN
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE
        cd.credit_rating = 'Good'
    GROUP BY
        c.customer_sk, c.customer_id, cd.credit_rating
    HAVING
        SUM(ws.ext_sales_price) >= 1000
),
customer_returns AS (
    SELECT
        wr.returning_customer_sk AS customer_sk,
        SUM(wr.return_amt) AS total_returns
    FROM
        web_returns wr
    GROUP BY
        wr.returning_customer_sk
)
SELECT
    ss.warehouse_name,
    ss.total_sales,
    ss.order_count,
    COALESCE(hv.total_spent, 0) AS total_spent_by_high_value_customers,
    COALESCE(cr.total_returns, 0) AS total_returns
FROM
    sales_summary ss
LEFT JOIN
    high_value_customers hv ON ss.warehouse_sk = hv.customer_sk
LEFT JOIN
    customer_returns cr ON hv.customer_sk = cr.customer_sk
WHERE
    ss.rank <= 5
ORDER BY
    ss.total_sales DESC;
