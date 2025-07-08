
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
),
top_products AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    'Top Products: ' || LISTAGG(tp.i_item_id, ', ') WITHIN GROUP (ORDER BY tp.i_item_id) AS top_products
FROM 
    high_value_customers hvc
CROSS JOIN 
    top_products tp
GROUP BY 
    hvc.c_customer_id, hvc.total_sales
ORDER BY 
    hvc.total_sales DESC;
