
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws.ws_quantity) as total_quantity,
        COUNT(DISTINCT ws.ws_order_number) as total_orders,
        AVG(ws.ws_ext_sales_price) as avg_sales_price
    FROM 
        customer c 
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
),
ranking_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY total_quantity DESC) as order_rank
    FROM 
        customer_info c
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    COALESCE(total_quantity, 0) as quantity,
    ABS(total_orders) as orders,
    CASE 
        WHEN total_quantity >= 100 THEN 'High Value'
        WHEN total_quantity > 0 THEN 'Medium Value'
        ELSE 'Low Value'
    END as value_category
FROM 
    ranking_info r
    LEFT JOIN customer_info ci ON r.c_customer_sk = ci.c_customer_sk
WHERE 
    r.order_rank = 1 AND 
    r.c_customer_sk IN (
        SELECT c_current_cdemo_sk 
        FROM customer 
        WHERE c_current_cdemo_sk IS NOT NULL
    )
ORDER BY 
    quantity DESC NULLS LAST
LIMIT 500
UNION ALL
SELECT 
    NULL as c_customer_sk,
    'Total' as c_first_name,
    NULL as c_last_name,
    SUM(total_quantity) as total_quantity,
    SUM(total_orders) as total_orders,
    CASE 
        WHEN SUM(total_quantity) >= 10000 THEN 'High Aggregate Value'
        ELSE 'Low Aggregate Value'
    END as aggregate_category
FROM 
    customer_info
WHERE 
    total_quantity >= 1
GROUP BY 
    total_quantity
HAVING 
    COUNT(*) > 0
ORDER BY 
    total_quantity DESC;
