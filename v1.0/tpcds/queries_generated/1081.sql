
WITH SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        w.w_warehouse_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rnk
    FROM 
        web_sales ws
    INNER JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        ws.ws_web_site_sk, w.w_warehouse_id
),

HighValueSales AS (
    SELECT 
        ss.ws_web_site_sk,
        ss.w_warehouse_id,
        ss.total_sales,
        ss.order_count,
        CASE 
            WHEN ss.total_sales > 100000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS sales_category
    FROM 
        SalesSummary ss
    WHERE 
        ss.rnk <= 5
)

SELECT 
    hvs.ws_web_site_sk,
    hvs.w_warehouse_id,
    hvs.total_sales,
    hvs.order_count,
    hvs.sales_category,
    COALESCE(NULLIF(AVG(CASE 
        WHEN cs.cs_sales_price > 0 THEN cs.cs_sales_price 
        ELSE NULL 
    END), 0), 'No sales') AS avg_catalog_sales
FROM 
    HighValueSales hvs
LEFT JOIN 
    catalog_sales cs ON hvs.ws_web_site_sk = cs.cs_bill_cdemo_sk
GROUP BY 
    hvs.ws_web_site_sk, hvs.w_warehouse_id, hvs.total_sales, hvs.order_count, hvs.sales_category
ORDER BY 
    hvs.total_sales DESC;
