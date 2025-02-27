
WITH RecursiveSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    UNION ALL
    SELECT 
        cs.cs_ship_mode_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_ship_mode_sk ORDER BY cs.cs_net_profit DESC) AS rn
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
), 
TotalProfit AS (
    SELECT 
        web.web_site_sk,
        SUM(web.ws_net_profit) as total_web_profit,
        COALESCE(SUM(cat.cs_net_profit), 0) as total_catalog_profit
    FROM 
        web_sales web
    LEFT JOIN 
        catalog_sales cat ON web.ws_web_site_sk = cat.cs_ship_mode_sk AND web.ws_order_number = cat.cs_order_number
    WHERE 
        web.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        web.web_site_sk
), 
RankedProfit AS (
    SELECT 
        tp.web_site_sk,
        tp.total_web_profit,
        tp.total_catalog_profit,
        CASE 
            WHEN tp.total_web_profit > tp.total_catalog_profit THEN 'Web'
            WHEN tp.total_web_profit < tp.total_catalog_profit THEN 'Catalog'
            ELSE 'Equal'
        END as profit_source
    FROM 
        TotalProfit tp
)
SELECT 
    rp.web_site_sk,
    rp.total_web_profit,
    rp.total_catalog_profit,
    rp.profit_source,
    RANK() OVER (ORDER BY rp.total_web_profit + rp.total_catalog_profit DESC) AS profit_rank
FROM 
    RankedProfit rp
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer_address ca 
        WHERE ca.ca_country IS NOT NULL 
        AND ca.ca_country <> 'USA'
        AND EXISTS (
            SELECT 1 
            FROM customer c 
            WHERE c.c_current_addr_sk = ca.ca_address_sk 
            AND c.c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns)
        )
    )
OPTION (MAXRECURSION 0);
