WITH sales_summary AS (
    SELECT 
        ws_web_site_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_revenue,
        SUM(ws_ext_tax) AS total_tax,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600  
    GROUP BY 
        ws_web_site_sk
),
top_websites AS (
    SELECT 
        ws.web_site_id, 
        ss.total_orders, 
        ss.total_revenue, 
        ss.total_tax, 
        ss.average_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_revenue DESC) AS rn
    FROM 
        sales_summary ss
    JOIN web_site ws ON ss.ws_web_site_sk = ws.web_site_sk
)
SELECT 
    tw.web_site_id, 
    tw.total_orders, 
    tw.total_revenue, 
    tw.total_tax, 
    tw.average_profit,
    w.w_warehouse_id,
    c.c_first_name,
    c.c_last_name
FROM 
    top_websites tw
JOIN warehouse w ON w.w_warehouse_sk = (SELECT inv_warehouse_sk 
                                           FROM inventory 
                                           WHERE inv_quantity_on_hand > 100 
                                           LIMIT 1)
JOIN store s ON s.s_store_sk = (SELECT sr_store_sk 
                                  FROM store_returns 
                                  WHERE sr_return_quantity > 5 
                                  ORDER BY sr_returned_date_sk DESC 
                                  LIMIT 1)
JOIN customer c ON c.c_customer_sk IN (SELECT sr_customer_sk 
                                         FROM store_returns 
                                         WHERE sr_store_sk = s.s_store_sk)
WHERE 
    tw.rn <= 10;