
WITH sales_summary AS (
    SELECT 
        w.warehouse_name,
        d.d_date AS sales_date,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    JOIN 
        date_dim d ON ss_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    GROUP BY 
        w.warehouse_name, d.d_date
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(ws_order_number) AS web_orders,
        COUNT(cs_order_number) AS catalog_orders,
        COUNT(ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
ranked_sales AS (
    SELECT 
        warehouse_name,
        sales_date,
        total_sales,
        avg_net_profit,
        transaction_count,
        RANK() OVER (PARTITION BY warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    COALESCE(r.sales_rank, 0) AS sales_rank,
    r.total_sales,
    r.avg_net_profit,
    r.transaction_count
FROM 
    customer_summary cs
LEFT JOIN 
    ranked_sales r ON cs.web_orders + cs.catalog_orders + cs.store_orders > 0 AND r.warehouse_name LIKE '%Main%'
WHERE 
    cs.cd_purchase_estimate > 1000 OR (cs.cd_gender = 'M' AND cs.cd_marital_status = 'S')
ORDER BY 
    total_sales DESC NULLS LAST
LIMIT 50;
