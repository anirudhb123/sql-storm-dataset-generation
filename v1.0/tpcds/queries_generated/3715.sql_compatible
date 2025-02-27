
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        ss.total_quantity,
        ss.total_revenue,
        ss.avg_profit,
        RANK() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
),
active_customers AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT ws_order_number) > 5
),
returns_summary AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt) AS total_return_value
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
)
SELECT 
    ti.i_item_id,
    ti.total_quantity,
    ti.total_revenue,
    ti.avg_profit,
    ac.c_customer_id,
    ac.order_count,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_value, 0) AS total_return_value
FROM 
    top_items ti
JOIN 
    active_customers ac ON ti.total_quantity > 100
LEFT JOIN 
    returns_summary rs ON ti.ws_item_sk = rs.cr_item_sk
WHERE 
    ti.revenue_rank <= 10
ORDER BY 
    ti.total_revenue DESC;
