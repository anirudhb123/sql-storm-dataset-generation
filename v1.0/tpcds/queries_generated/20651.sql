
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
SalesAnalysis AS (
    SELECT 
        r.web_site_id,
        r.total_net_profit,
        r.sales_rank,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.purchase_estimate
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics cd ON r.sales_rank = 1 AND cd.purchase_estimate > 1000
)
SELECT 
    s2.web_site_id,
    COALESCE(s2.total_net_profit, 0) AS total_net_profit,
    s2.sales_rank,
    s2.cd_gender,
    s2.cd_marital_status
FROM 
    SalesAnalysis s2
FULL OUTER JOIN 
    (SELECT 
        web_site_id,
        COUNT(web_site_id) AS site_count 
     FROM 
        web_site 
     GROUP BY 
        web_site_id) ws2 ON s2.web_site_id = ws2.web_site_id
WHERE 
    ws2.site_count IS NULL OR s2.total_net_profit > 10000
ORDER BY 
    s2.total_net_profit DESC, s2.cd_gender, s2.cd_marital_status;
