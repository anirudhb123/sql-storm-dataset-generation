
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        ranked_sales.total_quantity_sold, 
        ranked_sales.total_revenue
    FROM 
        ranked_sales
    JOIN 
        item ON ranked_sales.ws_item_sk = item.i_item_sk
    WHERE 
        ranked_sales.revenue_rank <= 10
),
customer_data AS (
    SELECT 
        customer.c_customer_id, 
        customer.c_first_name, 
        customer.c_last_name, 
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        customer.c_customer_id, customer.c_first_name, customer.c_last_name
),
purchase_summary AS (
    SELECT 
        customer_data.c_customer_id,
        customer_data.c_first_name,
        customer_data.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_ordered,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer_data
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = customer_data.c_customer_id 
    GROUP BY 
        customer_data.c_customer_id, customer_data.c_first_name, customer_data.c_last_name
)
SELECT 
    ts.i_item_id,
    ts.i_product_name,
    ps.c_customer_id,
    ps.c_first_name,
    ps.c_last_name,
    ps.total_orders,
    ps.total_items_ordered,
    ps.total_spent
FROM 
    top_items ts
JOIN 
    purchase_summary ps ON ps.total_spent > 1000
ORDER BY 
    ts.total_revenue DESC, ps.total_spent DESC;
