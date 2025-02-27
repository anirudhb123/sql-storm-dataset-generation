
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022 AND d.d_moy IN (1, 2, 3))
), TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        rs.ws_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
), StoreSales AS (
    SELECT 
        ss.ss_item_sk, 
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022 AND d.d_dow IN (1, 2, 3, 4))
    GROUP BY 
        ss.ss_item_sk
), CombinedSales AS (
    SELECT 
        ts.ws_item_sk, 
        ts.ws_order_number, 
        ts.ws_net_profit, 
        COALESCE(ss.total_store_profit, 0) AS total_store_profit
    FROM 
        TopSales ts
    LEFT JOIN 
        StoreSales ss ON ts.ws_item_sk = ss.ss_item_sk
), FinalResults AS (
    SELECT 
        cs.ws_item_sk,
        COUNT(DISTINCT cs.ws_order_number) AS order_count,
        SUM(cs.ws_net_profit) AS total_web_profit,
        MAX(cs.total_store_profit) AS max_store_profit,
        SUM(cs.total_store_profit) AS total_combined_profit,
        CASE 
            WHEN SUM(cs.ws_net_profit) > 1000 THEN 'High Earnings'
            WHEN SUM(cs.ws_net_profit) > 500 THEN 'Moderate Earnings'
            ELSE 'Low Earnings'
        END AS earnings_category,
        STRING_AGG(DISTINCT CONCAT('Order: ', cs.ws_order_number), '; ') as order_details
    FROM 
        CombinedSales cs
    GROUP BY 
        cs.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    fr.*
FROM 
    customer c
LEFT JOIN 
    FinalResults fr ON fr.ws_item_sk = c.c_customer_sk
WHERE 
    (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 12)
    AND (fr.total_combined_profit IS NOT NULL OR fr.total_combined_profit > 0)
ORDER BY 
    fr.total_combined_profit DESC, c.c_last_name ASC;
