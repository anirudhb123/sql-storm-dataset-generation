
WITH sales_data AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_quantity) AS avg_quantity,
        s_store_name,
        d_year
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        s_store_name, d_year
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales_per_store,
        AVG(total_orders) AS avg_orders_per_store,
        AVG(avg_quantity) AS avg_quantity_per_order,
        d_year
    FROM 
        sales_data
    GROUP BY 
        d_year
)
SELECT 
    y.d_year,
    y.avg_sales_per_store,
    y.avg_orders_per_store,
    y.avg_quantity_per_order,
    CASE 
        WHEN y.avg_sales_per_store > (SELECT AVG(avg_sales_per_store) FROM avg_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    avg_sales y
ORDER BY 
    y.d_year DESC;
