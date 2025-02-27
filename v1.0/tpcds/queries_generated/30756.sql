
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date >= '2022-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    INNER JOIN sales_dates sd ON d.d_date_sk = sd.d_date_sk + 1
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_sales, cs.total_orders,
           RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM customer_sales cs
    INNER JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > 1000
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
cross_sales AS (
    SELECT 
        tw.c_customer_sk,
        tw.c_first_name,
        tw.c_last_name,
        COALESCE(ws.total_sales, 0) AS web_sales_total,
        COALESCE(cs.total_sales, 0) AS store_sales_total,
        COALESCE(ws.total_sales, 0) + COALESCE(cs.total_sales, 0) AS total_combined_sales
    FROM top_customers tw
    LEFT JOIN web_sales ws ON tw.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales cs ON tw.c_customer_sk = cs.ss_customer_sk
),
final_output AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        w.w_warehouse_sk,
        ws.warehouse_sales,
        cs.total_combined_sales
    FROM cross_sales cs
    LEFT JOIN warehouse_sales w ON cs.c_customer_sk = w.w_warehouse_sk
    WHERE cs.total_combined_sales > 1000
)
SELECT *
FROM final_output
ORDER BY total_combined_sales DESC, c_last_name;
