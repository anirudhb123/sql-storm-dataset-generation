
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IS NOT NULL
      AND (c.c_first_name LIKE 'A%' OR c.c_last_name LIKE 'B%')
    GROUP BY ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        r.bill_customer_sk,
        r.total_sales,
        r.order_count,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS rank
    FROM ranked_sales r
    WHERE r.sales_rank <= 5
),
discount_analysis AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.order_number) AS discount_order_count
    FROM web_sales ws
    JOIN top_customers tc ON ws.bill_customer_sk = tc.bill_customer_sk 
    WHERE ws.ext_discount_amt IS NOT NULL
    GROUP BY ws.bill_customer_sk
)
SELECT 
    c.c_first_name AS customer_first_name,
    c.c_last_name AS customer_last_name,
    tc.total_sales,
    da.total_discount,
    CASE 
        WHEN da.discount_order_count > 0 THEN (da.total_discount / da.discount_order_count)
        ELSE 0
    END AS average_discount_per_order,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM top_customers tc
LEFT JOIN customer c ON tc.bill_customer_sk = c.c_customer_sk
LEFT JOIN discount_analysis da ON da.bill_customer_sk = tc.bill_customer_sk
WHERE tc.rank <= 10
ORDER BY tc.total_sales DESC, c.c_first_name, c.c_last_name;
