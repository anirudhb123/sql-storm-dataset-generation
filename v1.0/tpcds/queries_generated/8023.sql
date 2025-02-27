
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        YEAR(dd.d_date) AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id, YEAR(dd.d_date)
), ranking AS (
    SELECT 
        web_site_id,
        sales_year,
        total_sales,
        total_orders,
        avg_sales_price,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    r.web_site_id,
    r.sales_year,
    r.total_sales,
    r.total_orders,
    r.avg_sales_price,
    r.sales_rank
FROM 
    ranking r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_year, r.sales_rank;
