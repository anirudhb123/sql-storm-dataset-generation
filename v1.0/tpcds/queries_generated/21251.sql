
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        EXISTS (
            SELECT 1 
            FROM customer_demographics cd
            WHERE 
                cd.cd_demo_sk = c.c_current_cdemo_sk 
                AND cd.cd_gender = 'F' 
                AND cd.cd_marital_status = 'M'
        )
    GROUP BY ws.web_site_sk
),
total_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM catalog_sales cs
    FULL OUTER JOIN store_sales ss ON cs.cs_order_number = ss.ss_ticket_number
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk OR ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT 
    wa.w_warehouse_id,
    COALESCE(ts.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(ts.total_store_sales, 0) AS total_store_sales,
    COALESCE(tr.total_sales, 0) AS total_web_sales,
    (CASE
        WHEN COALESCE(ts.total_catalog_sales, 0) > 0 THEN 'Catalog sales lead'
        WHEN COALESCE(ts.total_store_sales, 0) > 0 THEN 'Store sales lead'
        ELSE 'No sales recorded'
    END) AS sales_lead_comment
FROM warehouse wa
LEFT JOIN total_sales ts ON wa.w_warehouse_sk = ts.w_warehouse_sk
LEFT JOIN ranked_sales tr ON tr.web_site_sk = wa.w_warehouse_sk
WHERE total_catalog_sales IS NOT NULL OR total_store_sales IS NOT NULL
ORDER BY total_web_sales DESC, sales_lead_comment, wa.w_warehouse_id
LIMIT 10;
