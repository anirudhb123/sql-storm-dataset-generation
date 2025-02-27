
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs.customer_sk,
        cs.bill_customer_sk,
        0 AS level,
        cs_net_profit
    FROM catalog_sales cs
    WHERE cs.net_profit > 0
    
    UNION ALL
    
    SELECT 
        cs.customer_sk,
        cs.bill_customer_sk,
        sh.level + 1 AS level,
        cs_net_profit
    FROM catalog_sales cs
    INNER JOIN SalesHierarchy sh ON cs.bill_customer_sk = sh.customer_sk
    WHERE sh.level < 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        (SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit)) AS grand_total_profit 
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
ProfitThreshold AS (
    SELECT 
        *,
        CASE 
            WHEN grand_total_profit > 1000 THEN 'High Profit'
            WHEN grand_total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM CustomerStats
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY profit_category ORDER BY grand_total_profit DESC) AS profit_rank
    FROM ProfitThreshold 
),
FinalOutput AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.grand_total_profit,
        tc.profit_category,
        sh.level,
        sh.cs_net_profit
    FROM TopCustomers tc
    LEFT JOIN SalesHierarchy sh ON tc.c_customer_sk = sh.customer_sk
    WHERE tc.profit_rank <= 10
)
SELECT 
    fo.c_first_name,
    fo.c_last_name,
    fo.cd_gender,
    fo.grand_total_profit,
    fo.profit_category,
    MAX(fo.level) AS max_level,
    COUNT(DISTINCT fo.cs_net_profit) AS distinct_net_profits
FROM FinalOutput fo
GROUP BY fo.c_first_name, fo.c_last_name, fo.cd_gender, fo.grand_total_profit, fo.profit_category
ORDER BY fo.grand_total_profit DESC;
