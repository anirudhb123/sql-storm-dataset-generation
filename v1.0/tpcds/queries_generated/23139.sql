
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_birth_month = 12 AND c.c_birth_day = 25
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE c.c_birth_month NOT IN (1, 2) AND (c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = 'Y')
),
PurchaseSummary AS (
    SELECT cd.cd_demo_sk, SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
),
StoreStats AS (
    SELECT s.s_store_sk, 
           COUNT(DISTINCT ss.ss_ticket_number) AS total_sales, 
           AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk
)
SELECT 
    ch.c_first_name || ' ' || ch.c_last_name AS Customer_Name,
    coalesce(ps.total_profit, 0) AS Total_Profit,
    ss.total_sales AS Total_Store_Sales,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales Data'
        WHEN ss.total_sales > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS Sales_Category,
    ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY ps.total_profit DESC) AS Profit_Rank
FROM CustomerHierarchy ch
LEFT JOIN PurchaseSummary ps ON ch.c_customer_sk = ps.cd_demo_sk
LEFT JOIN StoreStats ss ON ss.s_store_sk = (SELECT s.s_store_sk FROM store s ORDER BY RANDOM() LIMIT 1)
WHERE NOT EXISTS (
    SELECT 1 
    FROM store_returns sr 
    WHERE sr.sr_customer_sk = ch.c_customer_sk
      AND sr.sr_return_quantity > 0
)
ORDER BY Customer_Name
FETCH FIRST 50 ROWS ONLY;
