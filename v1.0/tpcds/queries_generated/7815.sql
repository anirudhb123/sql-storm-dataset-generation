
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        AVG(ws.ext_sales_price) AS avg_order_value,
        SUM(ws.quantity) AS total_quantity,
        MAX(d.d_date) AS last_order_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.gender = 'F' AND 
        cd.marital_status = 'M'
    GROUP BY 
        ws.web_site_id
),
RankedSales AS (
    SELECT 
        ss.web_site_id,
        ss.total_orders,
        ss.total_sales,
        ss.avg_order_value,
        ss.total_quantity,
        ss.last_order_date,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
)
SELECT 
    r.web_site_id,
    r.total_orders,
    r.total_sales,
    r.avg_order_value,
    r.total_quantity,
    r.last_order_date,
    r.sales_rank,
    w.w_warehouse_id,
    w.w_state,
    w.w_city
FROM 
    RankedSales r
JOIN 
    warehouse w ON r.web_site_id = w.w_warehouse_id
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
