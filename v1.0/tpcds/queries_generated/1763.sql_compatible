
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
AverageSales AS (
    SELECT
        web_site_sk,
        AVG(total_sales) AS avg_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    wa.w_warehouse_name,
    COALESCE(as.avg_sales, 0) AS average_sales,
    COUNT(rs.ws_order_number) AS total_orders
FROM 
    warehouse wa
LEFT JOIN 
    RankedSales rs ON wa.w_warehouse_sk = rs.web_site_sk
LEFT JOIN 
    AverageSales as ON wa.w_warehouse_sk = as.web_site_sk
GROUP BY 
    wa.w_warehouse_name, as.avg_sales
HAVING 
    COALESCE(as.avg_sales, 0) > 1000
ORDER BY 
    average_sales DESC;
