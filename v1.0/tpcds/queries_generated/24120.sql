
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.sold_date_sk,
        ws.item_sk,
        ws.order_number,
        ws.quantity,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rank_profit,
        SUM(ws.net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_site_profit,
        COALESCE(MAX(ws.net_profit) OVER (PARTITION BY ws.web_site_sk), 0) AS max_profit
    FROM 
        web_sales ws
),
HighProfitStores AS (
    SELECT 
        s.store_id,
        s.store_name,
        s.city,
        SUM(sales.total_profit) AS total_profit
    FROM 
        store s
    JOIN 
        (SELECT 
            ss.store_sk, 
            SUM(ss.net_profit) AS total_profit
        FROM 
            store_sales ss
        GROUP BY 
            ss.store_sk
        HAVING 
            SUM(ss.net_profit) > 1000
        ) sales ON s.store_sk = sales.store_sk 
    GROUP BY 
        s.store_id, s.store_name, s.city
)
SELECT 
    ca.ca_city AS address_city,
    ca.ca_state AS state,
    SUM(COALESCE(ranked.quantity, 0)) AS total_quantity,
    SUM(COALESCE(ranked.rank_profit, 0)) AS ranked_profit,
    COUNT(DISTINCT h.store_id) AS high_profit_stores_count
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales ranked ON ranked.item_sk = c.c_first_sales_date_sk
LEFT JOIN 
    HighProfitStores h ON h.city = ca.ca_city
WHERE 
    (ranked.rank_profit = 1 OR ranked.max_profit > 0)
    AND (ca.ca_state IS NOT NULL OR ca.ca_country = 'USA')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ranked.order_number) > 10 
    AND SUM(ranked.quantity) > 50 
ORDER BY 
    total_quantity DESC NULLS LAST;
