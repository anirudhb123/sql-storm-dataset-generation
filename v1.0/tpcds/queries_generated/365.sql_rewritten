WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2001 AND d.d_dow IN (2, 3) 
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_sales.c_customer_sk,
        c_sales.c_first_name,
        c_sales.c_last_name,
        c_sales.total_sales,
        RANK() OVER (ORDER BY c_sales.total_sales DESC) AS sales_rank
    FROM customer_sales c_sales
)
SELECT 
    t_customers.c_customer_sk,
    t_customers.c_first_name,
    t_customers.c_last_name,
    t_customers.total_sales,
    COALESCE(i.quantity_in_stock, 0) AS quantity_in_stock,
    CASE 
        WHEN t_customers.total_sales > 1000 THEN 'High Value'
        WHEN t_customers.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM top_customers t_customers
LEFT JOIN (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS quantity_in_stock
    FROM inventory inv 
    GROUP BY inv.inv_item_sk
) i ON i.inv_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = t_customers.c_customer_sk LIMIT 1) 
WHERE t_customers.sales_rank <= 10 
ORDER BY t_customers.total_sales DESC;