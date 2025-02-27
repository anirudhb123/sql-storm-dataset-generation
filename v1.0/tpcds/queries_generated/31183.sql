
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
    UNION ALL
    SELECT 
        ws_ship_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    JOIN 
        sales_summary ss ON ws_ship_date_sk = ss.ws_ship_date_sk + 1
    GROUP BY 
        ws_ship_date_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
mask AS (
    SELECT 
        'XP-' || LPAD(CAST(c_customer_sk AS text), 10, '0') AS customer_id,
        total_spent,
        order_count,
        avg_order_value
    FROM 
        customer_stats
    WHERE 
        total_spent IS NOT NULL
),
ranked_customers AS (
    SELECT 
        customer_id,
        total_spent,
        order_count,
        avg_order_value,
        RANK() OVER (PARTITION BY order_count ORDER BY total_spent DESC) AS rank
    FROM 
        mask
)
SELECT 
    rc.customer_id,
    rc.total_spent,
    rc.order_count,
    rc.avg_order_value,
    ss.total_orders,
    ss.total_revenue,
    ss.total_items_sold
FROM 
    ranked_customers rc
LEFT JOIN 
    sales_summary ss ON ss.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)
WHERE 
    rc.rank <= 10 
    AND rc.total_spent > (SELECT AVG(total_spent) FROM customer_stats)
ORDER BY 
    rc.total_spent DESC;
