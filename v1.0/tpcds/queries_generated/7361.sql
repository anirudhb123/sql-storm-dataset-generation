
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY DATE(d_sold_date_sk) ORDER BY SUM(ws_ext_sales_price) DESC) AS daily_rank
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        ws_bill_customer_sk, d_sold_date_sk
),

top_customers AS (
    SELECT 
        ca_state,
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        ss.total_sales,
        ss.total_discount,
        ss.order_count
    FROM 
        sales_summary ss
    JOIN 
        customer ON ss.ws_bill_customer_sk = customer.c_customer_sk
    JOIN 
        customer_address ON customer.c_current_addr_sk = ca_address_sk
    WHERE 
        ss.daily_rank <= 10
)

SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS num_top_customers,
    SUM(total_sales) AS total_sales_amount,
    AVG(total_discount) AS avg_discount_per_customer,
    COUNT(CASE WHEN order_count > 1 THEN 1 END) AS count_repeat_customers
FROM 
    top_customers
GROUP BY 
    ca_state
ORDER BY 
    total_sales_amount DESC;
