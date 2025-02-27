
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND c.c_birth_month IN (1, 2, 3) -- Select for the first quarter
    GROUP BY ws.ws_item_sk, ws.ws_order_number, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.total_quantity,
        rs.total_net_profit
    FROM RankedSales rs
    WHERE rs.rank_profit <= 10
),
StoreSales AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
CombinedSales AS (
    SELECT 
        COALESCE(ts.ws_item_sk, ss.ss_item_sk) AS item_sk,
        COALESCE(ts.total_quantity, 0) AS web_quantity,
        COALESCE(ts.total_net_profit, 0) AS web_net_profit,
        COALESCE(ss.store_quantity, 0) AS store_quantity,
        COALESCE(ss.store_net_profit, 0) AS store_net_profit
    FROM TopSales ts
    FULL OUTER JOIN StoreSales ss ON ts.ws_item_sk = ss.ss_item_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cs.item_sk,
    cs.web_quantity,
    cs.web_net_profit,
    cs.store_quantity,
    cs.store_net_profit,
    CASE 
        WHEN cs.web_net_profit > cs.store_net_profit THEN 'Web Sales Lead'
        WHEN cs.web_net_profit < cs.store_net_profit THEN 'Store Sales Lead'
        ELSE 'Equal Performance'
    END AS sales_lead
FROM CombinedSales cs
JOIN customer c ON cs.web_net_profit > 0 OR cs.store_net_profit > 0
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE (cs.web_net_profit + cs.store_net_profit) IS NOT NULL
AND (cs.web_quantity + cs.store_quantity) > 0
ORDER BY cs.item_sk, sales_lead DESC;
