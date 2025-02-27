
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_revenue
    FROM RankedSales rs
    WHERE rs.revenue_rank <= 10
),
CustomerPurchases AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
    )
    GROUP BY c.c_customer_sk
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cp.total_spent,
    tsi.total_quantity,
    tsi.total_revenue
FROM customer c
JOIN CustomerPurchases cp ON c.c_customer_sk = cp.c_customer_sk
JOIN TopSellingItems tsi ON tsi.ws_item_sk IN (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk
)
ORDER BY cp.total_spent DESC, tsi.total_revenue DESC;
