
WITH Revenue AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_revenue,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        MIN(ws.ws_sold_date_sk) AS first_sale_date,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk >= 20220101
    GROUP BY 
        ws.web_site_sk
),
SalesData AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(cs.cs_order_number) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_revenue
    FROM 
        catalog_sales cs
    JOIN 
        warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE 
        cs.cs_sold_date_sk >= 20220101
    GROUP BY 
        w.w_warehouse_id
),
ReturnData AS (
    SELECT 
        sr.s_store_sk,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        store s ON sr.sr_store_sk = s.s_store_sk
    WHERE 
        sr.sr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        sr.s_store_sk
)
SELECT 
    r.web_site_sk,
    r.total_revenue,
    r.order_count,
    r.avg_order_value,
    s.total_catalog_sales,
    s.total_catalog_revenue,
    rt.total_store_loss,
    rt.total_returns
FROM 
    Revenue r
LEFT JOIN 
    SalesData s ON r.web_site_sk = s.total_catalog_sales
LEFT JOIN 
    ReturnData rt ON r.web_site_sk = rt.s_store_sk
ORDER BY 
    r.total_revenue DESC
LIMIT 100;
