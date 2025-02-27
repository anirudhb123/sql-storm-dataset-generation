
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_with_ranks AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales_net_paid,
        cs.total_orders,
        cs.item_count,
        RANK() OVER (ORDER BY cs.total_sales_net_paid DESC) AS sales_rank
    FROM 
        customer_sales cs
),
top_customers AS (
    SELECT 
        swr.c_customer_sk,
        swr.total_sales_net_paid,
        swr.total_orders,
        swr.item_count
    FROM 
        sales_with_ranks swr
    WHERE 
        swr.sales_rank <= 100
),
sales_by_payment_method AS (
    SELECT 
        swr.c_customer_sk,
        CASE
            WHEN ws.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'CARRIER') THEN 'CARRIER'
            WHEN ws.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'OFFSET') THEN 'OFFSET'
            ELSE 'OTHER'
        END AS payment_method,
        SUM(ws.ws_net_paid) AS total_paid
    FROM 
        web_sales ws
    JOIN 
        top_customers tc ON ws.ws_ship_customer_sk = tc.c_customer_sk
    GROUP BY 
        swr.c_customer_sk,
        CASE
            WHEN ws.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'CARRIER') THEN 'CARRIER'
            WHEN ws.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'OFFSET') THEN 'OFFSET'
            ELSE 'OTHER'
        END
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales_net_paid,
    tc.total_orders,
    tc.item_count,
    sbpm.payment_method,
    sbpm.total_paid
FROM 
    top_customers tc
LEFT JOIN 
    sales_by_payment_method sbpm ON tc.c_customer_sk = sbpm.c_customer_sk
WHERE 
    sbpm.total_paid IS NOT NULL
ORDER BY 
    tc.total_sales_net_paid DESC, sbpm.total_paid DESC;
