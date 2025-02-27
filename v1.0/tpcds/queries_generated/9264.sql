
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND i.i_category = 'Electronics'
    GROUP BY 
        ws.web_site_id
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS store_total_quantity,
        SUM(ss.ss_net_profit) AS store_total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    s.web_site_id,
    s.total_quantity AS web_total_quantity,
    s.total_profit AS web_total_profit,
    s.order_count AS web_order_count,
    w.warehouse_id,
    w.store_total_quantity,
    w.store_total_profit,
    w.store_order_count
FROM 
    SalesSummary s
FULL OUTER JOIN 
    WarehouseSales w ON s.web_site_id = w.w_warehouse_id
WHERE 
    (s.web_total_quantity > 1000 OR w.store_total_quantity > 1000)
ORDER BY 
    COALESCE(s.web_total_profit, 0) DESC, 
    COALESCE(w.store_total_profit, 0) DESC;
