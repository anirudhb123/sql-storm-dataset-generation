
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.net_profit DESC) AS profit_rank,
        ws.sold_date_sk,
        dd.d_date
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
),
TopWebsites AS (
    SELECT 
        web_site_id, 
        SUM(net_profit) AS total_profit
    FROM RankedSales
    WHERE profit_rank <= 5
    GROUP BY web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_level
    FROM customer_demographics cd
)
SELECT 
    cw.w_warehouse_id,
    SUM(ws.ws_net_profit) AS warehouse_total_net_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    STRING_AGG(DISTINCT cd.purchase_level, ', ') AS purchase_levels
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN warehouse cw ON s.s_company_id = cw.w_warehouse_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN TopWebsites tw ON cw.w_warehouse_id = tw.web_site_id
WHERE ss.ss_sales_price > 0
GROUP BY cw.w_warehouse_id
ORDER BY warehouse_total_net_profit DESC
LIMIT 10;
