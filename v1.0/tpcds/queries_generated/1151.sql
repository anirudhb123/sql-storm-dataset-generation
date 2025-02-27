
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM
        CustomerSales
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CA.ca_city,
    CA.ca_state,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = tc.c_customer_sk) AS store_order_count
FROM
    TopCustomers tc
LEFT JOIN customer_address CA ON CA.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk LIMIT 1)
WHERE
    tc.rank <= 10
ORDER BY
    total_sales DESC;

WITH RECURSIVE SalesHierarchy AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        1 AS depth
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
    UNION ALL
    SELECT
        ws.us_item_sk,
        sh.total_sales + SUM(ws.ws_ext_sales_price) AS total_sales,
        depth + 1
    FROM
        web_sales ws
    JOIN SalesHierarchy sh ON ws.ws_item_sk = sh.ws_item_sk
    GROUP BY
        ws.ws_item_sk, sh.total_sales, depth
)
SELECT
    *
FROM
    SalesHierarchy
WHERE
    total_sales > 1000
ORDER BY
    depth, total_sales DESC;
