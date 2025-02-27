
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk BETWEEN 2450001 AND 2450200
    GROUP BY 
        ws.web_site_id
)
SELECT 
    r.web_site_id,
    r.total_quantity_sold,
    r.total_net_profit
FROM 
    RankedSales r
WHERE 
    r.rank <= 10
ORDER BY 
    r.total_net_profit DESC;
