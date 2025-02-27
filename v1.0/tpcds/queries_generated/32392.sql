
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450599
    GROUP BY c.c_customer_sk, c.c_customer_id
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        so.total_sales + s.s_sales_price AS total_sales,
        so.order_count + 1 AS order_count,
        RANK() OVER (ORDER BY (so.total_sales + s.s_sales_price) DESC)
    FROM sales_hierarchy so
    JOIN store_sales s ON so.c_customer_sk = s.ss_customer_sk
    WHERE s.ss_sold_date_sk BETWEEN 2450000 AND 2450599
),
monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(ws.ws_ext_sales_price) AS total_monthly_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND CURRENT_DATE
    GROUP BY sales_year, sales_month
),
average_sales AS (
    SELECT 
        sales_year,
        sales_month,
        AVG(total_monthly_sales) AS avg_sales
    FROM monthly_sales
    GROUP BY sales_year, sales_month
)
SELECT 
    sh.c_customer_id,
    sh.total_sales,
    sh.order_count,
    ms.sales_year,
    ms.sales_month,
    as.avg_sales,
    CASE 
        WHEN sh.total_sales IS NULL THEN 'No Sales'
        WHEN sh.total_sales > as.avg_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM sales_hierarchy sh
LEFT JOIN average_sales as ON EXTRACT(YEAR FROM CURRENT_DATE) = as.sales_year 
AND EXTRACT(MONTH FROM CURRENT_DATE) = as.sales_month
WHERE sh.sales_rank <= 10
ORDER BY sh.total_sales DESC;
