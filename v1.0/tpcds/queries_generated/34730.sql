
WITH RECURSIVE CustomerHierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        1 AS level,
        NULL AS parent_id
    FROM
        customer c
    WHERE
        c.c_customer_sk < 1000  -- base case for customers with IDs less than 1000

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1,
        ch.c_customer_id AS parent_id
    FROM
        customer c
    JOIN
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE
        ch.level < 5  -- limit the depth of the hierarchy to 5 levels
),
AggregatedReturns AS (
    SELECT
        coalesce(sr.cdemo_sk, cr.refunded_cdemo_sk) AS demo_sk,
        SUM(coalesce(sr.return_amt, 0) + coalesce(cr.return_amount, 0)) AS total_return_amt,
        COUNT(DISTINCT coalesce(sr.ticket_number, cr.order_number)) AS return_count
    FROM
        store_returns sr
    FULL OUTER JOIN
        catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
    GROUP BY
        demo_sk
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    ch.c_customer_id,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0)) AS net_sales,
    RANK() OVER (ORDER BY (COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0)) DESC) AS sales_rank,
    ch.level
FROM
    CustomerHierarchy ch
LEFT JOIN
    CustomerSales s ON ch.c_customer_sk = s.c_customer_sk
LEFT JOIN
    AggregatedReturns r ON ch.c_customer_sk = r.demo_sk
WHERE
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0)) > 0
ORDER BY
    sales_rank
LIMIT 100;
