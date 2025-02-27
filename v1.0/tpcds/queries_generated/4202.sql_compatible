
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND 
        ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_current_cdemo_sk, c.c_customer_id
),
top_customers AS (
    SELECT 
        rs.c_customer_id,
        rs.total_sales,
        rs.order_count
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_amount
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
HAVING 
    SUM(sr.sr_return_quantity) IS NOT NULL
ORDER BY 
    total_sales DESC, c.c_customer_id;
