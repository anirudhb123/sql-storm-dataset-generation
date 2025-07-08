
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(CASE WHEN ws.ws_sales_price > 100 THEN 1 END) AS high_value_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), sales_ranking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        cs.high_value_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
top_customers AS (
    SELECT 
        tr.*,
        CASE 
            WHEN tr.sales_rank <= 10 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        sales_ranking tr
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales_amount,
    COALESCE(tc.order_count, 0) AS total_orders,
    COALESCE(tc.avg_order_value, 0) AS average_order_value,
    COALESCE(tc.high_value_orders, 0) AS high_value_order_count,
    tc.customer_type
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    tc.total_sales DESC, tc.customer_type DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
