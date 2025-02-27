
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales + COALESCE((SELECT SUM(ws_ext_sales_price) 
                                    FROM web_sales 
                                    WHERE ws_ship_customer_sk = cs.c_customer_sk), 0),
        cs.total_orders + COALESCE((SELECT COUNT(ws_order_number) 
                                    FROM web_sales 
                                    WHERE ws_ship_customer_sk = cs.c_customer_sk), 0)
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales < 1000
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 0
),
filtered_customers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        tc.total_sales,
        tc.total_orders
    FROM 
        top_customers tc
    JOIN 
        customer c ON tc.c_customer_sk = c.c_customer_sk
    WHERE 
        tc.sales_rank <= 10
)
SELECT 
    fc.first_name || ' ' || fc.last_name AS customer_name,
    fc.total_sales,
    fc.total_orders,
    CASE 
        WHEN fc.total_sales IS NULL THEN 'No Sales'
        WHEN fc.total_sales < 500 THEN 'Low Value Customer'
        WHEN fc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_category,
    COALESCE(DATE(d.d_date) - 30, 'No Date Available') AS last_purchase_date,
    NULLIF(fc.total_orders, 0) AS orders_count
FROM 
    filtered_customers fc
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = fc.customer_sk)
WHERE 
    fc.total_sales IS NOT NULL
ORDER BY 
    fc.total_sales DESC;
