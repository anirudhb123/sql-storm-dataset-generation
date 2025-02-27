
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_quarter_seq AS sales_quarter,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        d.d_year, d.d_quarter_seq
),
average_sales AS (
    SELECT 
        sales_year,
        sales_quarter,
        total_sales / NULLIF(total_orders, 0) AS avg_sales_per_order,
        total_quantity / NULLIF(total_orders, 0) AS avg_quantity_per_order
    FROM 
        sales_summary
),
comparison AS (
    SELECT 
        a.sales_year,
        a.sales_quarter,
        a.avg_sales_per_order,
        b.avg_sales_per_order AS previous_year_avg_sales_per_order,
        CASE 
            WHEN b.avg_sales_per_order IS NULL THEN NULL
            ELSE ((a.avg_sales_per_order - b.avg_sales_per_order) / b.avg_sales_per_order) * 100
        END AS sales_growth_percentage
    FROM 
        average_sales a
    LEFT JOIN 
        average_sales b ON a.sales_year = b.sales_year + 1 AND a.sales_quarter = b.sales_quarter
)
SELECT 
    sales_year,
    sales_quarter,
    avg_sales_per_order,
    previous_year_avg_sales_per_order,
    sales_growth_percentage
FROM 
    comparison
ORDER BY 
    sales_year, sales_quarter;
