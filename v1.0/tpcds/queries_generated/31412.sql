
WITH RECURSIVE CustomerHierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        0 AS level
    FROM
        customer c
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM
        customer c
    JOIN
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
AggregatedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
BestCustomers AS (
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(as.total_sales, 0) AS total_sales,
        as.order_count
    FROM
        CustomerHierarchy ch
    LEFT JOIN
        AggregatedSales as ON ch.c_customer_sk = as.ws_bill_customer_sk
)
SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.total_sales,
    b.order_count,
    CASE
        WHEN b.total_sales > 1000 THEN 'Gold'
        WHEN b.total_sales BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier,
    (SELECT ROUND(AVG(total_sales), 2)
     FROM BestCustomers
     WHERE total_sales IS NOT NULL) AS average_sales
FROM
    BestCustomers b
WHERE
    b.total_sales IS NOT NULL
ORDER BY
    b.total_sales DESC
LIMIT 10;
