
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND cd.cd_gender IN ('M', 'F')
),
StoreSalesSummary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        AVG(ss.ss_net_profit) AS average_net_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_sk
)
SELECT 
    w.web_site_id,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    COALESCE(ss.average_net_profit, 0) AS average_net_profit
FROM 
    web_site w
LEFT JOIN 
    RankedSales rs ON w.web_site_sk = rs.web_site_sk AND rs.rank = 1
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk IN (SELECT DISTINCT ws.ws_bill_cdemo_sk FROM web_sales ws WHERE ws.ws_web_site_sk = w.web_site_sk)
LEFT JOIN 
    StoreSalesSummary ss ON ss.s_store_sk = (SELECT MAX(s_store_sk) FROM store)
WHERE 
    w.web_class = 'Electronics'
GROUP BY 
    w.web_site_id, rs.total_sales, ss.total_store_sales, ss.average_net_profit
ORDER BY 
    total_sales DESC, demographic_count DESC;
