
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_order_number,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        cs_item_sk,
        1 AS level
    FROM 
        catalog_sales
    GROUP BY 
        cs_order_number, cs_item_sk
    UNION ALL
    SELECT 
        cs.cs_order_number,
        sh.total_quantity + cs.cs_quantity,
        sh.total_profit + cs.cs_net_profit,
        cs.cs_item_sk,
        level + 1
    FROM 
        catalog_sales cs
        JOIN sales_hierarchy sh ON cs.cs_order_number = sh.cs_order_number
    WHERE 
        sh.level < 5
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    s.s_store_name,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    AVG(CASE WHEN sm.sm_ship_mode_id IS NOT NULL THEN ws.ws_net_paid ELSE NULL END) AS avg_web_sales_paid,
    COUNT(DISTINCT CASE WHEN sr.sr_ticket_number IS NOT NULL THEN sr.sr_ticket_number END) AS total_store_returns,
    COUNT(DISTINCT sh.cs_order_number) AS total_hierarchy_orders
FROM 
    customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN catalog_sales cs ON cs.cs_order_number IN (SELECT cs_order_number FROM sales_hierarchy)
    LEFT JOIN time_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_date, s.s_store_name
ORDER BY 
    total_sales DESC, total_web_returns DESC
LIMIT 100;
