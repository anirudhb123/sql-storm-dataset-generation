
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as sales_rank,
        COALESCE(ss.ss_net_profit, 0) AS store_net_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_order_number = ss.ss_order_number
),
frequent_customers AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 2
),
high_profit_items AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_ext_sales_price) AS total_sales
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_item_sk
    HAVING 
        SUM(sd.ws_ext_sales_price) > 1000
)
SELECT 
    DISTINCT c.c_first_name,
    c.c_last_name,
    f.order_count,
    h.total_sales,
    CASE 
        WHEN f.order_count BETWEEN 3 AND 5 THEN 'Regular'
        WHEN f.order_count > 5 THEN 'Frequent'
        ELSE 'Occasional'
    END AS customer_frequency
FROM 
    frequent_customers f
JOIN 
    customer c ON c.c_customer_id = f.c_customer_id
LEFT JOIN 
    high_profit_items h ON h.ws_item_sk IN (SELECT ws_item_sk FROM sales_data WHERE sales_rank = 1)
WHERE 
    c.c_birth_year IS NOT NULL
ORDER BY 
    h.total_sales DESC, 
    customer_frequency;
