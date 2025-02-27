
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM customer_sales
),
sales_with_average AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        a.avg_sales
    FROM top_customers tc
    CROSS JOIN average_sales a
)
SELECT 
    sw.c_customer_sk,
    sw.c_first_name,
    sw.c_last_name,
    sw.total_sales,
    sw.order_count,
    CASE 
        WHEN sw.total_sales > sw.avg_sales THEN 'Above Average'
        WHEN sw.total_sales < sw.avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_category
FROM sales_with_average sw
WHERE sw.sales_rank <= 10
ORDER BY sw.total_sales DESC;

-- Outer Joining Example with Shipping Information
SELECT 
    c.c_customer_id,
    c.c_first_name,
    COALESCE(ws.ws_ship_date_sk, 'No Ship Date') AS shipping_date,
    SUM(ws.ws_sales_price) AS total_ship_sales
FROM customer c
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY c.c_customer_id, c.c_first_name, ws.ws_ship_date_sk
HAVING SUM(ws.ws_sales_price) > 1000
ORDER BY total_ship_sales DESC;
