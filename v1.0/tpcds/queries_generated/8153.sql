
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk BETWEEN 6000 AND 10000
),
TopSales AS (
    SELECT 
        web_site_sk,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_quantity) AS total_quantity
    FROM 
        RankedSales
    WHERE 
        rank_sales <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    ts.avg_sales_price,
    ts.total_quantity
FROM 
    TopSales ts
JOIN 
    warehouse w ON ts.web_site_sk = w.w_warehouse_sk
ORDER BY 
    ts.avg_sales_price DESC;
