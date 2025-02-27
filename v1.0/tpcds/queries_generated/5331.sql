
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.total_orders,
        ss.total_sales,
        ss.total_discount,
        ss.total_profit
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ss.profit_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_sales,
    tc.total_discount,
    tc.total_profit,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.ws_bill_customer_sk)
ORDER BY 
    tc.total_profit DESC;
