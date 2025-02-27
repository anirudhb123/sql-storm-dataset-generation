
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND w.w_state = 'CA'
    GROUP BY 
        w.w_warehouse_id, p.p_promo_name, DATE(d.d_date)
),
RankedSales AS (
    SELECT 
        warehouse_id,
        promo_name,
        total_quantity,
        total_sales,
        total_orders,
        sales_date,
        RANK() OVER (PARTITION BY warehouse_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    warehouse_id,
    promo_name,
    total_quantity,
    total_sales,
    total_orders,
    sales_date
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    warehouse_id, sales_date;
