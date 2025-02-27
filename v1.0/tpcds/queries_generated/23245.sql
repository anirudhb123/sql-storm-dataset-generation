
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_net_profit IS NULL THEN 0
            WHEN ws.ws_net_profit < 0 THEN 0
            ELSE ws.ws_net_profit
        END AS adjusted_net_profit
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
    AND ws.ws_ship_date_sk IS NOT NULL
),
HighProfitItems AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_sales_price,
        r.adjusted_net_profit
    FROM RankedSales r
    WHERE r.price_rank = 1
    AND r.adjusted_net_profit > (
        SELECT AVG(adjusted_net_profit)
        FROM RankedSales
        WHERE adjusted_net_profit IS NOT NULL
    )
),
StoreSaleSummaries AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        AVG(ss.ss_net_profit) AS average_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT
    s.s_store_name,
    COALESCE(h.total_sales, 0) AS total_sales,
    COALESCE(s.total_ext_sales, 0) AS total_ext_sales,
    COALESCE(ss.average_net_profit, 0) AS average_net_profit,
    CASE
        WHEN h.total_sales = 0 THEN 'No Sales'
        WHEN h.total_sales IS NULL THEN 'Unknown Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM store s
LEFT JOIN StoreSaleSummaries ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN HighProfitItems h ON h.ws_item_sk IN (
    SELECT DISTINCT ws_item_sk FROM web_sales
)
WHERE s.s_state NOT IN ('CA', 'TX') 
AND (s.s_floor_space IS NOT NULL OR s.s_closed_date_sk IS NULL)
ORDER BY total_ext_sales DESC, average_net_profit ASC
LIMIT 100;
