
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CAST(NULL AS INTEGER) AS parent_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year < 1990
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name

    UNION ALL

    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.c_customer_sk AS parent_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        sh.c_customer_sk
),
sales_summary AS (
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        COALESCE(SUM(sh.total_orders), 0) AS total_orders,
        COALESCE(SUM(sh.total_sales), 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(sh.total_sales), 0) DESC) AS sales_rank
    FROM
        sales_hierarchy sh
    GROUP BY 
        sh.c_customer_sk, 
        sh.c_first_name, 
        sh.c_last_name
),
max_sales AS (
    SELECT
        MAX(total_sales) AS max_total_sales
    FROM
        sales_summary
)
SELECT
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_orders,
    ss.total_sales,
    CASE
        WHEN ss.total_sales = 0 THEN 'No Sales'
        WHEN ss.total_sales = (SELECT max_total_sales FROM max_sales) THEN 'Top Seller'
        ELSE 'Regular Customer'
    END AS customer_status
FROM
    sales_summary ss
WHERE
    ss.sales_rank <= 10
ORDER BY
    ss.total_sales DESC;
