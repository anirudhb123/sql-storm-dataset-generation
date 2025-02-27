
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_sold_date_sk, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_sk) AS total_quantity
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (c.c_birth_year BETWEEN 1970 AND 1990 OR c.c_birth_year IS NULL)
)
SELECT 
    r.web_site_sk,
    (CASE 
        WHEN r.total_quantity > 100 THEN 'High Volume'
        WHEN r.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END) AS volume_category,
    SUM(r.ws_net_profit) AS total_profit,
    AVG(CASE 
            WHEN r.rank_profit <= 5 THEN r.ws_net_profit 
            ELSE NULL 
        END) AS avg_top_profit
FROM 
    RankedSales r
WHERE 
    r.rank_profit <= 10
    AND EXISTS (
        SELECT 1 
        FROM customer_address ca 
        WHERE ca.ca_address_sk = r.web_site_sk 
        AND ca.ca_city IS NOT NULL
        HAVING COUNT(ca.ca_address_sk) > 0
    )
GROUP BY 
    r.web_site_sk, r.rank_profit, r.total_quantity
HAVING 
    SUM(r.ws_net_profit) > 1000
ORDER BY 
    total_profit DESC
FETCH FIRST 5 ROWS ONLY;
