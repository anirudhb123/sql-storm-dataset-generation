
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        w.warehouse_name,
        d.d_date,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit_margin
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
        AND cd.cd_gender = 'F'
        AND w.w_warehouse_sq_ft > 5000
    GROUP BY 
        ws.web_site_id, w.warehouse_name, d.d_date
),
DailySales AS (
    SELECT 
        web_site_id,
        warehouse_name,
        d_date,
        total_sales,
        order_count,
        avg_profit_margin,
        ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id,
    warehouse_name,
    d_date,
    total_sales,
    order_count,
    avg_profit_margin
FROM 
    DailySales
WHERE 
    sales_rank <= 10
ORDER BY 
    web_site_id, total_sales DESC;
