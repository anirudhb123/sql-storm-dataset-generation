
WITH RankedSales AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        ss.item_sk,
        SUM(ss.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.net_profit) DESC) AS profit_rank
    FROM store_sales ss
    WHERE ss.sold_date_sk > (
        SELECT MIN(ws.sold_date_sk) 
        FROM web_sales ws 
        WHERE ws.bill_customer_sk IS NOT NULL
    )
    GROUP BY ss.sold_date_sk, ss.store_sk, ss.item_sk
),
TopStores AS (
    SELECT 
        r.store_sk,
        SUM(r.total_profit) AS store_total_profit
    FROM RankedSales r
    WHERE r.profit_rank <= 5
    GROUP BY r.store_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        CASE 
            WHEN cd.dep_count IS NULL THEN 'No Dependency'
            WHEN cd.dep_count > 5 THEN 'High Dependency'
            ELSE 'Low to Moderate Dependency' 
        END AS dependency_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.gender, cd.marital_status, cd.education_status, cd.dep_count
),
FinalReport AS (
    SELECT 
        d.d_date_id,
        s.store_sk,
        s.store_total_profit,
        cd.gender,
        cd.dependency_status,
        COALESCE(NULLIF(total_profit, 0), SUM(ws.net_profit)) AS adjusted_profit
    FROM TopStores s
    LEFT JOIN date_dim d ON d.d_date_sk = (SELECT MIN(d2.d_date_sk) FROM date_dim d2) 
    LEFT JOIN CustomerDemographics cd ON cd.customer_count > 10
    LEFT JOIN web_sales ws ON ws.ship_date_sk = d.d_date_sk AND s.store_sk = ws.warehouse_sk
    GROUP BY d.d_date_id, s.store_sk, s.store_total_profit, cd.gender, cd.dependency_status, total_profit
)
SELECT 
    d.d_date_id,
    f.store_sk,
    f.store_total_profit,
    f.gender,
    f.dependency_status,
    f.adjusted_profit,
    CASE 
        WHEN f.store_total_profit > 10000 THEN 'High Revenue Store'
        WHEN f.store_total_profit BETWEEN 5000 AND 10000 THEN 'Moderate Revenue Store'
        ELSE 'Low Revenue Store' 
    END AS revenue_category
FROM FinalReport f
JOIN date_dim d ON f.d_date_id = d.d_date_id
WHERE d.d_year > 2020
ORDER BY f.store_total_profit DESC, f.gender;
