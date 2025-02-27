
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.total_orders
    FROM 
        customer c
    JOIN 
        ranked_sales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.sales_rank <= 10
),
sales_summary AS (
    SELECT 
        dd.d_year,
        SUM(ws_net_paid) AS yearly_sales,
        AVG(ws_net_paid) AS average_sales,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        dd.d_year
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    ss.yearly_sales,
    ss.average_sales,
    ss.unique_customers,
    ca.ca_city,
    ca.ca_state,
    NULLIF(ss.yearly_sales, 0) AS non_zero_sales_indicator
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON tc.ws_bill_customer_sk = ca.ca_address_sk
JOIN 
    sales_summary ss ON tc.ws_bill_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    ss.yearly_sales DESC
LIMIT 50;
