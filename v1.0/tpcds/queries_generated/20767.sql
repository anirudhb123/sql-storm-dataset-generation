
WITH RECURSIVE customer_profit AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_profit
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk
),
demographic_summary AS (
    SELECT
        cd.cd_gender,
        CD.cd_marital_status,
        COUNT(DISTINCT cp.c_customer_sk) AS customer_count,
        SUM(cp.total_profit) AS total_profit
    FROM
        customer_profit cp
    JOIN customer_demographics cd ON cp.c_customer_sk = c.c_customer_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
),
ranked_demographics AS (
    SELECT *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_profit DESC) AS profit_rank
    FROM demographic_summary
)
SELECT
    dd.cd_gender,
    dd.cd_marital_status,
    dd.customer_count,
    dd.total_profit,
    CASE WHEN dd.profit_rank = 1 THEN 'Top Performer' ELSE 'Regular' END AS performance_category
FROM ranked_demographics dd
WHERE
    dd.total_profit > (SELECT AVG(total_profit) FROM ranked_demographics) OR dd.cd_marital_status IS NULL
ORDER BY
    dd.cd_gender,
    dd.total_profit DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT
    'Unknown' AS cd_gender,
    'N/A' AS cd_marital_status,
    COUNT(*) AS customer_count,
    SUM(COALESCE(total_profit, 0)) AS total_profit
FROM customer_profit
WHERE c_customer_sk IS NULL;
