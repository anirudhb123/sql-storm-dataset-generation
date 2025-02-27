
WITH customer_spending AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        cs.total_orders,
        cs.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_spending cs
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_spending)
),
popular_items AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_sold DESC
    LIMIT 10
)
SELECT 
    hvc.c_customer_id,
    hvc.total_spent,
    hvc.total_orders,
    hvc.avg_order_value,
    pi.i_item_id,
    pi.total_sold,
    pi.avg_price
FROM 
    high_value_customers hvc
JOIN 
    popular_items pi ON hvc.total_spent > pi.avg_price
ORDER BY 
    hvc.total_spent DESC, pi.total_sold DESC;
