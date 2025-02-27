
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT ss.c_customer_id) AS customer_count,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_sales) AS total_sales,
        AVG(ss.avg_sales_price) AS avg_sales_price
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    ds.customer_count,
    ds.total_quantity,
    ds.total_sales,
    ds.avg_sales_price,
    RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
FROM 
    demographics_summary ds
JOIN 
    customer_demographics cd ON ds.cd_gender = cd.cd_gender
ORDER BY 
    ds.total_sales DESC;
