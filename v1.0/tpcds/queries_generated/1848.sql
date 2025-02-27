
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 1980
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(total_sales) AS warehouse_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        ranked_sales rs
    LEFT JOIN 
        web_site w ON rs.web_site_sk = w.web_site_sk
    GROUP BY 
        w.w_warehouse_id
),
top_sales AS (
    SELECT 
        warehouse_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY warehouse_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    t.warehouse_id,
    t.warehouse_sales,
    t.order_count,
    CASE 
        WHEN t.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Not Top 10'
    END AS sales_category
FROM 
    top_sales t
WHERE 
    t.order_count > 5
UNION 
SELECT 
    'Total' AS warehouse_id,
    SUM(warehouse_sales) AS warehouse_sales,
    SUM(order_count) AS order_count,
    'Aggregate' AS sales_category
FROM 
    top_sales
WHERE 
    order_count > 5;
