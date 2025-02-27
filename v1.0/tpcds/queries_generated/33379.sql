
WITH RECURSIVE sales_per_day AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS row_num
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk 
    GROUP BY 
        d.d_date
),
customer_statistics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS warehouse_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    s.d_date,
    COALESCE(s.total_sales, 0) AS daily_sales,
    cs.customer_count,
    cs.avg_purchase_estimate,
    ws.warehouse_sales,
    ws.order_count
FROM 
    sales_per_day s
FULL OUTER JOIN 
    customer_statistics cs ON s.row_num = (SELECT COUNT(*) FROM sales_per_day WHERE total_sales > s.total_sales)
LEFT JOIN 
    warehouse_sales ws ON ds.warehouse_sales IS NOT NULL

WHERE 
    (s.total_sales > 100 OR cs.customer_count IS NULL)
    AND (ws.order_count >= 10 OR ws.warehouse_sales IS NULL)
ORDER BY 
    s.d_date DESC;
