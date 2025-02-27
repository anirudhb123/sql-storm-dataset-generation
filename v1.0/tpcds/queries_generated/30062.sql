
WITH RECURSIVE sales_schedule AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DATE(d.d_date) AS sale_date
    FROM
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id, DATE(d.d_date)
    
    UNION ALL

    SELECT 
        w.w_warehouse_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        DATE(d.d_date) AS sale_date
    FROM
        warehouse w
    JOIN 
        catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN 
        date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id, DATE(d.d_date)
), sales_totals AS (
    SELECT 
        warehouse_id,
        SUM(total_sales) AS total_sales_year
    FROM 
        sales_schedule
    GROUP BY 
        warehouse_id
), customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS customer_total
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
), qualified_customers AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customers_count
    FROM 
        customer_demographics cd
    JOIN 
        customer_sales cs ON cd.cd_demo_sk = cs.c_customer_id
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    qt.cd_gender,
    qt.cd_marital_status,
    qt.customers_count,
    s.total_sales_year,
    CASE 
        WHEN qt.customers_count > 50 THEN 'High'
        WHEN qt.customers_count BETWEEN 21 AND 50 THEN 'Medium'
        ELSE 'Low'
    END AS segmentation_level
FROM 
    qualified_customers qt
JOIN 
    sales_totals s ON s.warehouse_id = qt.cd_gender
ORDER BY 
    qt.customers_count DESC;
