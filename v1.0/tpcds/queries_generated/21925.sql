
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws_ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws_net_profit DESC) AS RankProfit
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sales_price > 0
        AND w.web_gmt_offset IS NOT NULL
        AND (ws.ws_net_profit - (SELECT AVG(ws2.ws_net_profit) 
                                  FROM web_sales ws2 
                                  WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk
                                    AND ws2.ws_order_number IS NOT NULL)) > 100
)

SELECT 
    r.web_site_id,
    SUM(r.ws_quantity) AS Total_Quantity,
    COUNT(DISTINCT r.ws_order_number) AS Total_Orders,
    MAX(r.RankProfit) AS Highest_Rank_Profit
FROM 
    RankedSales r
GROUP BY 
    r.web_site_id
HAVING 
    SUM(r.ws_quantity) > (
        SELECT 
            AVG(SUM(ws_quantity)) 
        FROM 
            web_sales 
        GROUP BY 
            ws_web_site_sk
    )
    OR EXISTS (
        SELECT 
            1 
        FROM 
            customer c
        WHERE 
            c.c_current_cdemo_sk IS NOT NULL
            AND c.c_customer_sk IN (
                SELECT sr_customer_sk 
                FROM store_returns 
                WHERE sr_return_quantity < 0
            )
    )
ORDER BY 
    Total_Quantity DESC;

