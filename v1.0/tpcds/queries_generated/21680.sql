
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        COALESCE((SELECT COUNT(*) FROM customer c 
                   WHERE c.c_customer_sk IN (ws.ws_bill_customer_sk, ws.ws_ship_customer_sk)
                   AND c.c_birth_month = d.d_moy), 0) AS birth_month_count,
        STRING_AGG(DISTINCT r.r_reason_desc, ', ') AS reason_description
    FROM 
        web_sales ws
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        catalog_returns cr ON cr.cr_order_number = ws.ws_order_number
    LEFT JOIN 
        reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number, ws.ws_item_sk, ws.ws_sales_price
), 
AggregatedSales AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders,
        SUM(CASE WHEN rs.rn = 1 THEN rs.ws_sales_price END) AS highest_sales_price,
        AVG(COALESCE(rs.birth_month_count, 0)) AS avg_birth_month_customers,
        COUNT(DISTINCT CASE WHEN rs.reason_description IS NOT NULL THEN rs.ws_order_number END) AS orders_with_reason
    FROM 
        RankedSales rs
    JOIN 
        warehouse w ON w.w_warehouse_sk = (SELECT DISTINCT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_item_sk = rs.ws_item_sk LIMIT 1)
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ag.w_warehouse_name,
    ag.total_orders,
    COALESCE(ag.highest_sales_price, 0) AS highest_sales_price,
    ag.avg_birth_month_customers,
    ag.orders_with_reason,
    CONCAT('Warehouse ', ag.w_warehouse_name, ' processed ', ag.total_orders, ' orders; highest sale: ', COALESCE(ag.highest_sales_price, 0)) AS order_summary
FROM 
    AggregatedSales ag
WHERE 
    ag.total_orders > 0
    AND ag.avg_birth_month_customers > (SELECT AVG(hd_demo_sk) FROM household_demographics)
ORDER BY 
    ag.total_orders DESC
LIMIT 10;
