
WITH RECURSIVE CTE_Sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        1 AS level
    FROM store_sales
    GROUP BY ss_store_sk

    UNION ALL

    SELECT 
        s.ss_store_sk,
        SUM(ss.net_profit) + c.total_net_profit AS total_net_profit,
        COUNT(DISTINCT s.ss_ticket_number) + c.total_transactions AS total_transactions,
        c.level + 1
    FROM store_sales s
    JOIN CTE_Sales c ON s.ss_store_sk = c.ss_store_sk
    WHERE c.level < 5
    GROUP BY s.ss_store_sk, c.total_net_profit, c.total_transactions, c.level
),
Customer_Income AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS transaction_count,
        cd.cd_income_band_sk
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_sk, cd.cd_income_band_sk
),
Profit_Rank AS (
    SELECT 
        c.c_customer_sk,
        ci.cd_income_band_sk,
        ci.total_profit,
        RANK() OVER (PARTITION BY ci.cd_income_band_sk ORDER BY ci.total_profit DESC) AS profit_rank
    FROM Customer_Income ci
),
Final_Summary AS (
    SELECT 
        s.w_warehouse_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_profit) AS average_profit,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    LEFT JOIN warehouse s ON ss.ss_store_sk = s.w_warehouse_sk
    LEFT JOIN Profit_Rank pr ON ss.ss_customer_sk = pr.c_customer_sk
    WHERE pr.profit_rank <= 10
    GROUP BY s.w_warehouse_id
)
SELECT 
    w.w_warehouse_id,
    COALESCE(fs.total_transactions, 0) AS transactions,
    COALESCE(fs.average_profit, 0) AS avg_profit,
    COALESCE(fs.total_net_profit, 0) AS net_profit
FROM warehouse w
LEFT JOIN Final_Summary fs ON w.w_warehouse_id = fs.w_warehouse_id
WHERE w.w_country = 'USA'
ORDER BY fs.total_net_profit DESC;
