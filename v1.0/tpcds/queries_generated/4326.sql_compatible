
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT w.ws_order_number) AS total_web_orders,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_profit,
        SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_profit,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_orders,
        cs.total_web_profit,
        cs.total_catalog_profit,
        cs.total_store_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_web_profit DESC) AS web_profit_rank,
        DENSE_RANK() OVER (ORDER BY cs.total_catalog_profit DESC) AS catalog_profit_rank,
        DENSE_RANK() OVER (ORDER BY cs.total_store_profit DESC) AS store_profit_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    rc.c_customer_sk,
    rs.cd_gender,
    rs.cd_marital_status,
    rc.total_web_orders,
    rc.total_web_profit,
    rc.total_catalog_profit,
    rc.total_store_profit,
    CASE 
        WHEN rc.total_web_profit > 0 THEN 'High Web Profits'
        WHEN rc.total_catalog_profit > 0 AND rc.total_store_profit = 0 THEN 'Catalog Only'
        ELSE 'Low Activity'
    END AS customer_activity_profile
FROM 
    RankedCustomers rc
LEFT JOIN 
    Demographics rs ON rc.c_customer_sk = rs.cd_demo_sk
WHERE 
    rc.web_profit_rank <= 10 OR rc.catalog_profit_rank <= 10 OR rc.store_profit_rank <= 10
ORDER BY 
    rc.total_web_profit DESC, rc.total_catalog_profit DESC, rc.total_store_profit DESC;
