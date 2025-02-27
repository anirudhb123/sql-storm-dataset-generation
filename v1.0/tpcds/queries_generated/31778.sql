
WITH RECURSIVE sales_performance AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
active_customers AS (
    SELECT 
        c.c_customer_id,
        MAX(d.d_date) AS last_purchase_date,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        sp.c_customer_id,
        sp.total_net_profit,
        a.last_purchase_date,
        a.orders_count
    FROM 
        sales_performance sp
    JOIN 
        active_customers a ON sp.c_customer_id = a.c_customer_id
    WHERE 
        sp.order_rank <= 10
)
SELECT 
    t.c_customer_id,
    t.total_net_profit,
    t.last_purchase_date,
    COALESCE(t.orders_count, 0) AS orders_count
FROM 
    top_customers t
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = t.c_customer_id)
WHERE 
    cd.cd_gender = 'F'
ORDER BY 
    t.total_net_profit DESC;
