
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
HighProfitSales AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_quantity,
        COALESCE((SELECT SUM(ws2.ws_net_profit) 
                  FROM web_sales ws2 
                  WHERE ws2.ws_item_sk = r.ws_item_sk 
                  AND ws2.ws_order_number != r.ws_order_number), 0) AS total_net_profit_other_orders
    FROM 
        RankedSales r
    WHERE 
        r.rank_profit <= 5
),
MarketPerformance AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_net_profit) AS total_net_profit,
        AVG(s.ss_sales_price) AS avg_sales_price,
        STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotional_names
    FROM 
        store_sales s
        JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
        LEFT JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    WHERE 
        s.ss_net_profit IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
FinalReport AS (
    SELECT 
        hps.web_site_sk,
        hps.ws_order_number,
        hps.ws_item_sk,
        hps.ws_quantity,
        mp.total_sales,
        mp.total_net_profit,
        mp.avg_sales_price,
        CASE 
            WHEN mp.total_net_profit > 1000 THEN 'High Performer'
            WHEN mp.total_net_profit IS NULL THEN 'No Sales'
            ELSE 'Average Performer'
        END AS performance_category
    FROM 
        HighProfitSales hps
    LEFT JOIN MarketPerformance mp ON hps.web_site_sk = mp.c_customer_sk
)
SELECT 
    fr.web_site_sk,
    fr.ws_order_number,
    fr.ws_item_sk,
    fr.ws_quantity,
    fr.total_sales,
    fr.total_net_profit,
    fr.avg_sales_price,
    fr.performance_category
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > 0 OR fr.total_net_profit IS NOT NULL
ORDER BY 
    fr.total_net_profit DESC, 
    fr.ws_quantity DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
