
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.sold_date_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_birth_month IS NOT NULL
    GROUP BY 
        ws.web_site_sk, ws.sold_date_sk
), 
ReturnedSales AS (
    SELECT 
        wr.web_site_sk,
        SUM(wr.net_loss) AS total_net_loss
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_order_number = ws.ws_order_number 
    GROUP BY 
        wr.web_site_sk
), 
FinalReport AS (
    SELECT 
        w.warehouse_id,
        COALESCE(rs.total_net_profit, 0) AS net_profit,
        COALESCE(re.total_net_loss, 0) AS net_loss,
        (COALESCE(rs.total_net_profit, 0) - COALESCE(re.total_net_loss, 0)) AS effective_profit
    FROM 
        warehouse w
    LEFT JOIN 
        RankedSales rs ON w.warehouse_sk = rs.web_site_sk
    LEFT JOIN 
        ReturnedSales re ON w.warehouse_sk = re.web_site_sk
    WHERE 
        w.warehouse_sq_ft > 1000
        AND (
            rs.rank_profit = 1 
            OR (rs.rank_profit IS NULL AND re.total_net_loss > 100)
        )
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    effective_profit > 0
ORDER BY 
    effective_profit DESC
LIMIT 10;
