
WITH SalesData AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        dd.d_year AS sales_year,
        dd.d_month AS sales_month
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        c.c_customer_id, dd.d_year, dd.d_month
),
RankedSales AS (
    SELECT
        c_customer_id,
        total_quantity_sold,
        total_sales_amount,
        avg_sales_price,
        total_orders,
        sales_year,
        sales_month,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.c_customer_id,
    r.total_quantity_sold,
    r.total_sales_amount,
    r.avg_sales_price,
    r.total_orders,
    r.sales_year,
    r.sales_month
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_year DESC, 
    r.total_sales_amount DESC;
