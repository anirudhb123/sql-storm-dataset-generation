
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        DENSE_RANK() OVER (PARTITION BY ws.ws_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_order_number, ws.ws_site_sk
), SalesMetrics AS (
    SELECT 
        warehouse.w_warehouse_id,
        COALESCE(SUM(total_sales), 0) AS total_sales_by_warehouse,
        COUNT(*) AS order_count
    FROM 
        RankedSales
    FULL OUTER JOIN 
        warehouse ON RankedSales.ws_order_number IS NOT NULL
    GROUP BY 
        warehouse.w_warehouse_id
), SalesSummary AS (
    SELECT 
        s.warehouse_id,
        s.total_sales_by_warehouse,
        s.order_count,
        CASE 
            WHEN s.total_sales_by_warehouse > 10000 THEN 'High'
            WHEN s.total_sales_by_warehouse > 5000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        SalesMetrics s
)
SELECT 
    ss.warehouse_id,
    ss.total_sales_by_warehouse,
    ss.order_count,
    ss.sales_category,
    r.r_reason_desc AS return_reason,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns
FROM 
    SalesSummary ss
LEFT JOIN 
    catalog_returns cr ON ss.warehouse_id = cr.cr_warehouse_sk
LEFT JOIN 
    reason r ON cr.cr_reason_sk = r.r_reason_sk
GROUP BY 
    ss.warehouse_id, ss.total_sales_by_warehouse, ss.order_count, ss.sales_category, r.r_reason_desc
HAVING 
    SUM(cr.cr_return_amount) IS NULL OR SUM(cr.cr_return_amount) < 1000
ORDER BY 
    ss.total_sales_by_warehouse DESC;
