
WITH RecursiveCTE AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_year,
        ROW_NUMBER() OVER (PARTITION BY C.c_customer_sk ORDER BY C.c_birth_month, C.c_birth_year) AS rn
    FROM
        customer C
    WHERE
        C.c_birth_month IS NOT NULL
),
FilteredSales AS (
    SELECT
        W.ws_item_sk,
        SUM(W.ws_quantity) AS total_sales,
        AVG(W.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT W.ws_order_number) AS unique_orders,
        R.c_first_name,
        R.c_last_name
    FROM
        web_sales W
    JOIN RecursiveCTE R ON W.ws_bill_customer_sk = R.c_customer_sk
    GROUP BY
        W.ws_item_sk, R.c_first_name, R.c_last_name
),
MaxSales AS (
    SELECT
        *,
        MAX(total_sales) OVER (PARTITION BY c_first_name ORDER BY total_sales DESC) AS max_total_sales
    FROM
        FilteredSales
)
SELECT
    D.d_date,
    S.total_sales,
    S.avg_sales_price,
    CASE
        WHEN S.max_total_sales IS NULL THEN 'No Sales'
        WHEN S.max_total_sales = 0 THEN 'Zero Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM
    MaxSales S
JOIN date_dim D ON D.d_date_sk = (
    SELECT
        MAX(d_date_sk)
    FROM
        date_dim
    WHERE
        D.d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
WHERE
    S.total_sales IS NOT NULL OR 
    (S.total_sales IS NULL AND R.c_first_name LIKE '%a%')
ORDER BY
    D.d_date,
    S.total_sales DESC
LIMIT 50;

