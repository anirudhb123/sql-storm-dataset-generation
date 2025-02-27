
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND EXISTS (
            SELECT 1 
            FROM store s 
            WHERE s.s_store_sk = (SELECT sr_store_sk FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_quantity > 0)
        )
    GROUP BY 
        ws.web_site_sk
),
MaxProfitSite AS (
    SELECT 
        web_site_sk,
        MAX(total_net_profit) AS max_net_profit
    FROM 
        RankedSales
    WHERE 
        rank = 1
    GROUP BY 
        web_site_sk
)
SELECT 
    ws.web_site_id,
    ws.web_name,
    COALESCE(mp.max_net_profit, 0) AS highest_net_profit,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS top_customers
FROM 
    web_site ws
LEFT JOIN 
    MaxProfitSite mp ON ws.web_site_sk = mp.web_site_sk
LEFT JOIN 
    web_sales wsa ON ws.web_site_sk = wsa.ws_web_site_sk
LEFT JOIN 
    customer c ON wsa.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    COALESCE(mp.max_net_profit, 0) > 1000 
    AND NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_returning_customer_sk = c.c_customer_sk AND sr.sr_return_quantity IS NULL
    )
GROUP BY 
    ws.web_site_id, ws.web_name
ORDER BY 
    highest_net_profit DESC
LIMIT 5;
