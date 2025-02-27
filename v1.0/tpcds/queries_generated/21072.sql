
WITH RECURSIVE customer_income AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Unknown'
        END AS marital_status,
        COUNT(cd.cd_dep_count) OVER (PARTITION BY cd.cd_income_band_sk) AS dependent_count
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL
),
shop_sales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.ss_customer_sk
),
combined AS (
    SELECT 
        ci.c_customer_sk,
        ci.marital_status,
        ci.dependent_count,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        ss.transactions
    FROM 
        customer_income ci
    LEFT JOIN 
        shop_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    marital_status,
    COUNT(*) AS customer_count,
    AVG(total_profit) AS avg_profit,
    AVG(total_quantity) AS avg_quantity,
    MAX(transactions) AS max_transactions
FROM 
    combined
WHERE 
    dependent_count > 0
GROUP BY 
    marital_status
HAVING 
    avg_profit > (SELECT AVG(total_profit) FROM shop_sales) 
    OR marital_status = 'Married'
ORDER BY 
    customer_count DESC, 
    avg_profit DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
