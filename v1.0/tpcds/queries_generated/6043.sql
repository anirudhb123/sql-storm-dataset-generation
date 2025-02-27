
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS pages_visited,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
),
store_sales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ss.ss_store_sk
),
promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_net_paid) AS promo_sales,
        COUNT(ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d) 
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cs.c_customer_id,
    cs.total_net_paid,
    cs.total_orders,
    cs.pages_visited,
    cs.avg_quantity_per_order,
    ss.total_store_sales,
    ss.total_store_orders,
    p.promo_sales,
    p.promo_order_count
FROM 
    customer_sales cs
LEFT JOIN 
    store_sales ss ON ss.total_store_sales > 10000 -- Filter for profitable stores
LEFT JOIN 
    promotions p ON p.promo_sales > 5000 -- Include only successful promotions
ORDER BY 
    cs.total_net_paid DESC, ss.total_store_sales DESC
LIMIT 100;
