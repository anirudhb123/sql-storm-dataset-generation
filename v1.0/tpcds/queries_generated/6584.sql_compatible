
WITH RankedSales AS (
    SELECT 
        w.warehouse_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        w.warehouse_sk, w.warehouse_name
)

SELECT 
    rs.warehouse_name,
    rs.total_sales,
    rs.order_count,
    (SELECT AVG(total_sales) FROM RankedSales) AS average_sales,
    CASE 
        WHEN rs.total_sales > (SELECT AVG(total_sales) FROM RankedSales) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS sales_performance
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.total_sales DESC;
