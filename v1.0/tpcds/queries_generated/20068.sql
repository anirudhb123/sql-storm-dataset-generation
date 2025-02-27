
WITH RankedReturns AS (
    SELECT 
        sr.store_sk,
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.return_quantity,
        sr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.store_sk ORDER BY sr.return_amt DESC) AS rn
    FROM 
        store_returns sr
),
CustomerPromotions AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT p.p_promo_id) AS promotion_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        promotion p ON c.c_customer_sk = p.p_promo_id
    GROUP BY 
        c.c_customer_sk
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.net_profit) AS total_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state = 'CA' AND ss.net_profit IS NOT NULL
    GROUP BY 
        s.s_store_sk
),
IncomeBandAnalysis AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
FinalResults AS (
    SELECT 
        cs.c_customer_sk,
        ts.total_profit,
        r.returned_date_sk,
        ib.household_count,
        ib.avg_vehicle_count
    FROM 
        CustomerPromotions cs
    JOIN 
        TopStores ts ON cs.promotion_count > 3
    LEFT JOIN 
        RankedReturns r ON cs.c_customer_sk = r.store_sk
    LEFT JOIN 
        IncomeBandAnalysis ib ON ib.household_count > 10
    WHERE 
        ts.total_profit > 1000000
)
SELECT 
    c_customer_sk,
    SUM(total_profit) AS total_profit,
    MAX(household_count) AS max_household_count,
    COUNT(DISTINCT returned_date_sk) AS return_date_count
FROM 
    FinalResults
WHERE 
    total_profit IS NOT NULL 
GROUP BY 
    c_customer_sk
HAVING 
    COUNT(DISTINCT returned_date_sk) > 1 AND 
    MAX(household_count) IS NOT NULL
ORDER BY 
    total_profit DESC
LIMIT 10;
