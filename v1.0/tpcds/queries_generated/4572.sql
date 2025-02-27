
WITH AggregateSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_online_profit,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE
            WHEN ib.ib_income_band_sk IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS income_status
    FROM
        customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
RankedSales AS (
    SELECT
        a.c_customer_id,
        a.total_online_profit,
        a.total_catalog_profit,
        a.total_store_sales,
        cd.cd_gender,
        cd.income_status,
        RANK() OVER (PARTITION BY cd.income_status ORDER BY a.total_online_profit DESC) AS profit_rank
    FROM
        AggregateSales a
    JOIN CustomerDemographics cd ON a.c_customer_id = cd.cd_demo_sk
)
SELECT
    r.c_customer_id,
    r.total_online_profit,
    r.total_catalog_profit,
    r.total_store_sales,
    r.cd_gender,
    r.income_status,
    CASE 
        WHEN r.profit_rank <= 10 THEN 'Top Performer'
        WHEN r.profit_rank <= 50 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM
    RankedSales r
WHERE
    r.total_online_profit IS NOT NULL
    AND r.total_catalog_profit IS NOT NULL
ORDER BY r.total_online_profit DESC, r.total_catalog_profit DESC;
