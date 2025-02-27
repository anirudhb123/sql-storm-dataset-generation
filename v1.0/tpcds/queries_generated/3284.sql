
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
        AND ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_sk
),
TopSales AS (
    SELECT 
        ss.web_site_sk,
        ss.total_orders,
        ss.total_profit,
        ss.total_sales
    FROM 
        SalesSummary ss
    WHERE 
        ss.rank_profit <= 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.net_profit) AS warehouse_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    t.web_site_sk,
    t.total_orders,
    t.total_profit,
    t.total_sales,
    ws.warehouse_profit,
    CASE 
        WHEN t.total_profit IS NULL THEN 'No Sales' 
        ELSE 'Sales Present' 
    END AS sales_status
FROM 
    TopSales t
FULL OUTER JOIN 
    WarehouseSales ws ON t.web_site_sk = ws.warehouse_profit
ORDER BY 
    COALESCE(t.total_profit, 0) DESC, 
    COALESCE(ws.warehouse_profit, 0) DESC
LIMIT 50;
