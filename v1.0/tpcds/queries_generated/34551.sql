
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.net_paid) AS total_sales,
        COUNT(ss.ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_web_orders,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(sd.total_sales) AS annual_sales,
        AVG(sd.total_transactions) AS avg_transactions_per_item
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    s.annual_sales,
    s.avg_transactions_per_item,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    top_customers tc
LEFT JOIN 
    sales_summary s ON tc.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_first_name = tc.c_first_name AND c_last_name = tc.c_last_name LIMIT 1)
WHERE 
    s.annual_sales IS NOT NULL
ORDER BY 
    s.annual_sales DESC, tc.sales_rank;
