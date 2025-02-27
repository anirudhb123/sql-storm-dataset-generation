
WITH RECURSIVE SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        DATE(d.d_date) AS order_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS order_rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2022
    UNION ALL
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        DATE(d.d_date) AS order_date,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_item_sk) AS order_rank
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2022
),
TotalSales AS (
    SELECT
        order_number,
        SUM(ws_sales_price * ws_quantity) AS total_sales_value,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM
        SalesData
    GROUP BY
        order_number
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ts.order_number) AS total_orders,
        SUM(ts.total_sales_value) AS total_sales
    FROM
        customer c
    LEFT JOIN
        TotalSales ts ON c.c_customer_sk = ts.order_number
    GROUP BY
        c.c_customer_sk
),
NullLogic AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_sales,
        CASE
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales > 1000 THEN 'High Value Customer'
            ELSE 'Low Value Customer'
        END AS customer_type
    FROM
        CustomerSales cs
)
SELECT
    c.c_first_name,
    c.c_last_name,
    nl.total_orders,
    nl.total_sales,
    nl.customer_type
FROM
    customer c
JOIN
    NullLogic nl ON c.c_customer_sk = nl.c_customer_sk
WHERE
    (nl.total_orders > 0 OR nl.total_sales IS NOT NULL)
ORDER BY
    nl.total_sales DESC
LIMIT 100;
