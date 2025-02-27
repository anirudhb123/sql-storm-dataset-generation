
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        customer_id,
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
),
sales_by_state AS (
    SELECT 
        ca_state,
        SUM(total_sales) AS state_sales
    FROM 
        top_customers tc
    JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
    GROUP BY 
        ca_state
)
SELECT 
    s.ca_state,
    s.state_sales,
    RANK() OVER (ORDER BY s.state_sales DESC) AS sales_rank
FROM 
    sales_by_state s
WHERE 
    s.state_sales > 0
ORDER BY 
    s.state_sales DESC;
