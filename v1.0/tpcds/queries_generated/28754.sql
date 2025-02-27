
WITH CustomerPurchase AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ss.ss_sales_price, 0)) DESC) AS spending_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.gender,
        c.total_spent,
        c.web_orders,
        c.catalog_orders,
        c.store_orders
    FROM
        CustomerPurchase c
    WHERE
        c.spending_rank <= 10
)
SELECT
    t.customer_id,
    t.first_name,
    t.last_name,
    t.gender,
    t.total_spent,
    t.web_orders,
    t.catalog_orders,
    t.store_orders,
    CONCAT(t.first_name, ' ', t.last_name) AS full_name,
    REPLACE(t.customer_id, 'CUST-', '') AS customer_number
FROM
    TopCustomers t
ORDER BY
    t.total_spent DESC;
