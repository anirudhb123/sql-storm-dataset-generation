
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
    HAVING SUM(ws_net_profit) > 0
),
SalesSummary AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sold_date_sk,
        r.total_quantity,
        r.total_profit,
        C.c_first_name,
        C.c_last_name,
        COALESCE(SUM(CASE WHEN r.total_profit > 1000 THEN 1 ELSE 0 END), 0) AS high_profit_sales
    FROM RankedSales r
    LEFT JOIN CustomerHierarchy C ON C.c_customer_sk = r.ws_item_sk
    GROUP BY r.ws_item_sk, r.ws_sold_date_sk, C.c_first_name, C.c_last_name
    HAVING high_profit_sales > 0
),
FinalOutput AS (
    SELECT 
        ss.ws_item_sk,
        SUM(ss.total_quantity) AS total_sales,
        AVG(ss.total_profit) AS average_profit,
        MAX(ss.high_profit_sales) AS max_high_profit_sales
    FROM SalesSummary ss
    GROUP BY ss.ws_item_sk
)
SELECT 
    FO.ws_item_sk,
    FO.total_sales,
    FO.average_profit,
    FO.max_high_profit_sales,
    COALESCE(ib.ib_lower_bound, 'Unknown') AS income_band
FROM FinalOutput FO
LEFT JOIN income_band ib ON FO.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE FO.average_profit IS NOT NULL
ORDER BY FO.total_sales DESC
LIMIT 100;
