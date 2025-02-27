
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        s.total_sales,
        s.order_count
    FROM 
        sales_hierarchy s
    JOIN 
        customer c ON s.c_customer_sk = c.c_customer_sk
    WHERE 
        s.sales_rank <= 10
),
shipping_costs AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
comprehensive_sales AS (
    SELECT 
        tc.c_customer_id,
        tc.total_sales,
        tc.order_count,
        COALESCE(sc.total_shipping_cost, 0) AS total_shipping_cost,
        (tc.total_sales + COALESCE(sc.total_shipping_cost, 0)) AS grand_total
    FROM 
        top_customers tc
    LEFT JOIN 
        shipping_costs sc ON tc.c_customer_id = sc.ws_order_number
)
SELECT 
    c.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.total_shipping_cost,
    cs.grand_total,
    CASE 
        WHEN cs.grand_total IS NULL OR cs.grand_total = 0 THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status
FROM 
    comprehensive_sales cs 
JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
ORDER BY 
    grand_total DESC
LIMIT 50;
