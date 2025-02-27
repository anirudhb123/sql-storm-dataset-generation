
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ship_date_sk IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ss.net_profit, 0) + COALESCE(cs.net_profit, 0) + COALESCE(ws.net_profit, 0)) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
income_distribution AS (
    SELECT
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(total_profit) AS avg_profit
    FROM customer_info ci
    JOIN customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
final_summary AS (
    SELECT
        id.cd_gender,
        id.customer_count,
        id.avg_profit,
        RANK() OVER (ORDER BY id.avg_profit DESC) AS rank_by_profit
    FROM income_distribution id
)
SELECT 
    f.cd_gender,
    f.customer_count,
    f.avg_profit,
    (SELECT AVG(avg_profit) FROM final_summary WHERE avg_profit < f.avg_profit) AS avg_of_lower_profits
FROM final_summary f
WHERE f.rank_by_profit <= 10 
ORDER BY f.avg_profit DESC
LIMIT 5
UNION ALL
SELECT 
    'TOTAL' AS cd_gender,
    COUNT(*) AS customer_count,
    SUM(ci.total_profit) AS avg_profit,
    NULL AS avg_of_lower_profits
FROM customer_info ci;
