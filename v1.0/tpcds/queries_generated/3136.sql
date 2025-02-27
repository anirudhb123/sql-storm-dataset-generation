
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
customer_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        cs.last_order_date,
        CASE 
            WHEN cs.total_web_sales IS NULL THEN 'No Sales'
            WHEN cs.total_web_sales < 1000 THEN 'Low Value'
            WHEN cs.total_web_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS customer_value_segment
    FROM customer_sales cs
),
top_customers AS (
    SELECT 
        csk.c_customer_sk,
        csk.c_first_name,
        csk.c_last_name,
        csk.total_web_sales,
        RANK() OVER (ORDER BY csk.total_web_sales DESC) AS sales_rank
    FROM customer_summary csk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tsr.total_orders,
    tsr.last_order_date,
    tc.customer_value_segment,
    (SELECT COUNT(DISTINCT s.s_store_sk) 
     FROM store s
     JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
     WHERE ss.ss_sold_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
     AND ss.ss_net_profit > 0) AS active_stores_count
FROM top_customers tc
LEFT JOIN customer_summary tsr ON tc.c_customer_sk = tsr.c_customer_sk
WHERE tc.sales_rank <= 10
ORDER BY tc.total_web_sales DESC;
