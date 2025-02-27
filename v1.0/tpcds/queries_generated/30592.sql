
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
    UNION ALL
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        sh.level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_hierarchy sh ON ws_bill_customer_sk = sh.cs_bill_customer_sk
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_sales,
        ROW_NUMBER() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.cs_bill_customer_sk
    WHERE 
        sh.total_sales IS NOT NULL
),
product_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    ps.total_quantity,
    ps.total_revenue,
    CASE 
        WHEN ps.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    top_customers tc
LEFT JOIN 
    product_summary ps ON tc.c_customer_sk = ps.i_item_sk
WHERE 
    (ps.total_revenue IS NOT NULL OR tc.sales_rank <= 20)
ORDER BY 
    tc.total_sales DESC, 
    ps.total_revenue DESC
LIMIT 50;
