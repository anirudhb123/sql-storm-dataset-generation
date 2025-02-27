
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        COALESCE(ws.ws_net_profit, 0) AS net_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
FilteredSales AS (
    SELECT 
        web_site_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_value,
        MAX(net_profit) AS max_profit
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_sk
),
TopWebsites AS (
    SELECT 
        w.warehouse_name, 
        f.total_sales_quantity,
        f.total_sales_value,
        f.max_profit,
        DENSE_RANK() OVER (ORDER BY f.max_profit DESC) AS profit_rank
    FROM 
        warehouse w
    JOIN 
        FilteredSales f ON w.w_warehouse_sk = f.web_site_sk
)
SELECT 
    t.warehouse_name,
    t.total_sales_quantity,
    t.total_sales_value,
    t.max_profit,
    CASE 
        WHEN t.profit_rank = 1 THEN 'Top Performer'
        WHEN t.profit_rank IS NULL THEN 'No Sales'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    TopWebsites t
WHERE 
    t.total_sales_value > 10000
    OR t.max_profit IS NULL
ORDER BY 
    t.profit_rank;
