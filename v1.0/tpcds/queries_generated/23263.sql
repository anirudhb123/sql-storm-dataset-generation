
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
        AND (s.s_state IS NULL OR s.s_state IN ('NY', 'CA'))
    GROUP BY 
        ws.web_site_sk, 
        ws.ws_order_number
),
TopSales AS (
    SELECT 
        web_site_sk, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    w.warehouse_id,
    COALESCE(SUM(ts.total_sales), 0) AS total_top_sales,
    SUM(CASE WHEN ts.total_sales IS NOT NULL THEN 1 ELSE 0 END) AS top_sales_count,
    AVG(ts.total_sales) FILTER (WHERE ts.total_sales IS NOT NULL) AS avg_top_sales,
    COUNT(ts.total_sales) AS total_count,
    COUNT(DISTINCT w.warehouse_sk) AS total_warehouses
FROM 
    warehouse w
LEFT JOIN 
    TopSales ts ON w.warehouse_sk = ts.web_site_sk
GROUP BY 
    w.warehouse_id
HAVING 
    COUNT(ts.total_sales) < (SELECT COUNT(*) FROM web_sales) / 100
ORDER BY 
    total_top_sales DESC 
LIMIT 5;
