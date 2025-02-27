
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_sales AS (
    SELECT 
        c_customer_id,
        total_quantity,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        sales_summary
),
final_report AS (
    SELECT 
        ts.c_customer_id,
        ts.total_quantity,
        ts.total_sales,
        ts.sales_rank,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        top_sales ts
    JOIN 
        customer_demographics cd ON ts.c_customer_id = cd.cd_demo_sk
    WHERE 
        ts.sales_rank <= 10
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_quantity,
    f.cd_gender,
    f.cd_marital_status,
    f.sales_rank
FROM 
    final_report f
ORDER BY 
    f.total_sales DESC;
