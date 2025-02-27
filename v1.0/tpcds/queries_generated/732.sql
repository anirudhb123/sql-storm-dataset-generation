
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS items_purchased
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.items_purchased,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 5000
),
recent_orders AS (
    SELECT 
        ws.ws_bill_customer_sk,
        MAX(d.d_date) AS last_order_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ro.last_order_date,
        tc.total_sales
    FROM 
        top_customers tc
    LEFT JOIN 
        recent_orders ro ON tc.c_customer_sk = ro.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name || ' ' || ci.c_last_name AS customer_full_name,
    ci.total_sales,
    ci.last_order_date,
    CASE 
        WHEN ci.last_order_date IS NULL THEN 'No Orders'
        WHEN ci.last_order_date < CURRENT_DATE - INTERVAL '30 days' THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status
FROM 
    customer_info ci
WHERE 
    ci.sales_rank <= 10
ORDER BY 
    ci.total_sales DESC
LIMIT 5;
