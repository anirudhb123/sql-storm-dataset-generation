
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_inner.ws_sales_price) 
                              FROM web_sales ws_inner 
                              WHERE ws_inner.ws_web_site_sk = ws.web_site_sk) 
        AND ws.ws_quantity IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_sales_price) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.web_site_sk
)
SELECT 
    w.warehouse_id,
    COALESCE(ts.total_sales, 0) AS highest_sales,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(CASE WHEN c.c_birth_year IS NOT NULL THEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year END) AS average_age,
    CASE 
        WHEN w.warehouse_sq_ft IS NULL THEN 'Unknown Size'
        WHEN w.warehouse_sq_ft < 1000 THEN 'Small Warehouse'
        ELSE 'Large Warehouse'
    END AS warehouse_size_category
FROM 
    warehouse w
LEFT JOIN 
    TopSales ts ON w.warehouse_sk = ts.web_site_sk
LEFT JOIN 
    customer c ON c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_country = 'USA')
GROUP BY 
    w.warehouse_id, ts.total_sales
ORDER BY 
    highest_sales DESC, customer_count ASC
LIMIT 10;
