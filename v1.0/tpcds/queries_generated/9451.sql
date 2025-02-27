
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws_sold_date_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.web_page_sk = wp.web_page_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.web_site_sk, ws.order_number, ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_sk, 
        SUM(total_profit) AS cumulative_profit, 
        SUM(total_orders) AS cumulative_orders
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    ts.cumulative_profit,
    ts.cumulative_orders,
    COUNT(DISTINCT w.w_warehouse_sk) AS distinct_warehouses
FROM 
    TopSales ts
JOIN 
    warehouse w ON ts.web_site_sk = w.w_warehouse_sk
GROUP BY 
    w.warehouse_id, w.warehouse_name, ts.cumulative_profit, ts.cumulative_orders
ORDER BY 
    ts.cumulative_profit DESC;
