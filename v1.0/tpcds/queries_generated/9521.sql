
WITH ranked_orders AS (
    SELECT 
        ws.order_number,
        COUNT(ws.order_number) AS order_count,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_tax) AS avg_net_paid,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS customer_order_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1985 AND 1995
        AND ws.sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY 
        ws.order_number, ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(DISTINCT ws.order_number) AS unique_orders,
        SUM(ws.net_profit) AS total_profit,
        AVG(ws.net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.bill_customer_sk
    HAVING 
        COUNT(DISTINCT ws.order_number) > 5
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    tc.unique_orders,
    tc.total_profit,
    tc.avg_net_paid,
    ro.order_count,
    ro.total_profit AS order_total_profit,
    ro.avg_net_paid AS order_avg_net_paid
FROM 
    top_customers tc
JOIN 
    customer cu ON tc.bill_customer_sk = cu.c_customer_sk
LEFT JOIN 
    ranked_orders ro ON cu.c_customer_sk = ro.bill_customer_sk
WHERE 
    ro.customer_order_rank <= 10
ORDER BY 
    tc.total_profit DESC, tc.unique_orders DESC;
