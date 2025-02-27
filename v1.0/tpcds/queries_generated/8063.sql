
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND w.web_gmt_offset BETWEEN -5 AND -4
    GROUP BY 
        ws.web_site_id, ws.ws_web_site_sk
),

TopSites AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
)

SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.total_orders,
    ca.ca_city,
    wd.warehouse_name,
    COUNT(DISTINCT ws.ws_order_number) AS order_count_per_site
FROM 
    TopSites ts
JOIN 
    store_returns sr ON sr.sr_store_sk IN (
        SELECT DISTINCT s.s_store_sk 
        FROM store s 
        WHERE s.s_city IN (SELECT DISTINCT ca_city FROM customer_address)
    )
JOIN 
    warehouse wd ON sr.sr_store_sk = wd.w_warehouse_sk
JOIN 
    web_sales ws ON ts.web_site_id = ws.ws_web_site_sk
GROUP BY 
    ts.web_site_id, ts.total_sales, ts.total_orders, ca.ca_city, wd.warehouse_name
ORDER BY 
    ts.total_sales DESC;
