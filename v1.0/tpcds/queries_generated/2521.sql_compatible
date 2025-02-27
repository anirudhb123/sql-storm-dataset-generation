
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
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
sales_totals AS (
    SELECT
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS total_store_sales,
        cs.web_orders,
        cs.catalog_orders,
        cs.store_orders,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales,
        DENSE_RANK() OVER (ORDER BY (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) DESC) AS sales_rank
    FROM 
        customer_sales cs
),
high_spenders AS (
    SELECT 
        s.c_customer_id,
        s.total_sales,
        s.web_orders,
        s.catalog_orders,
        s.store_orders,
        CASE 
            WHEN s.total_sales > 1000 THEN 'High Value'
            WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_category
    FROM 
        sales_totals s
    WHERE 
        s.total_sales > (SELECT AVG(total_sales) FROM sales_totals)
)
SELECT 
    h.c_customer_id,
    h.total_sales,
    h.customer_category,
    h.web_orders,
    h.catalog_orders,
    h.store_orders
FROM 
    high_spenders h
WHERE 
    h.profile_updated IS NULL
ORDER BY 
    h.total_sales DESC;
