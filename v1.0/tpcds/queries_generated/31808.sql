
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_name,
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_sales_price,
        1 AS level
    FROM 
        store_sales
    JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk 
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    
    UNION ALL
    
    SELECT 
        s_store_name,
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity * 1.1 AS ss_quantity,
        ss_sales_price * 1.05 AS ss_sales_price,
        level + 1
    FROM 
        sales_hierarchy
    JOIN 
        store_sales ON store_sales.ss_item_sk = sales_hierarchy.ss_item_sk 
    JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk
    WHERE 
        level < 3
),
customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        customer c ON c.c_customer_sk = ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
ranked_customers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
aggregate_sales AS (
    SELECT
        sh.s_store_name,
        SUM(sh.ss_quantity) AS total_quantity,
        SUM(sh.ss_sales_price * sh.ss_quantity) AS total_revenue
    FROM 
        sales_hierarchy sh
    GROUP BY 
        sh.s_store_name
),
final_output AS (
    SELECT 
        ag.s_store_name,
        ag.total_quantity,
        ag.total_revenue,
        rc.c_first_name,
        rc.c_last_name,
        rc.sales_rank
    FROM 
        aggregate_sales ag
    JOIN 
        ranked_customers rc ON rc.sales_rank <= 10
)
SELECT 
    fo.s_store_name,
    fo.total_quantity,
    fo.total_revenue,
    COALESCE(fo.c_first_name || ' ' || fo.c_last_name, 'Unknown Customer') AS customer_name
FROM 
    final_output fo
ORDER BY 
    fo.total_revenue DESC
LIMIT 50;
