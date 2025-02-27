
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sale_price,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_ship_date_sk >= d.d_date_sk
        AND d.d_year IN (2021, 2022)
        AND cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT 
        web_site_id, 
        total_sales,
        total_orders,
        avg_sale_price,
        unique_customers,
        sales_year,
        sales_month,
        RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id, 
    r.total_sales, 
    r.total_orders, 
    r.avg_sale_price, 
    r.unique_customers, 
    r.sales_year, 
    r.sales_month
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.sales_year, r.sales_month, r.total_sales DESC;
