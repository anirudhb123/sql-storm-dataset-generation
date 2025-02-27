
WITH CustomerPromotions AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
FrequentCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_customer_id,
        ROW_NUMBER() OVER (PARTITION BY cp.c_customer_id ORDER BY cp.total_spent DESC) AS spending_rank
    FROM 
        CustomerPromotions cp
    WHERE 
        cp.promo_count > 0
),
TopSpendingCustomers AS (
    SELECT 
        fc.c_customer_id,
        fc.spending_rank,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        FrequentCustomers fc
    LEFT JOIN 
        customer_demographics cd ON fc.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON fc.c_customer_sk = hd.hd_demo_sk
    WHERE 
        fc.spending_rank <= 10
)
SELECT 
    t.c_customer_id,
    t.gender,
    t.marital_status,
    t.income_band,
    COALESCE((
        SELECT 
            AVG(ws.ws_net_paid) 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk = t.c_customer_id
        GROUP BY 
            ws.ws_bill_customer_sk
    ), 0) AS avg_spent,
    (
        SELECT 
            COUNT(DISTINCT sr_item_sk)
        FROM 
            store_returns sr 
        WHERE 
            sr.sr_customer_sk = t.c_customer_id
    ) AS total_returns
FROM 
    TopSpendingCustomers t
WHERE 
    t.gender IS NOT NULL 
    AND t.marital_status = 'M' 
    AND (t.income_band = -1 OR t.income_band IN (SELECT ib_income_band_sk FROM income_band WHERE ib_upper_bound > 50000))
ORDER BY 
    avg_spent DESC
LIMIT 5
UNION ALL 
SELECT 
    'Aggregate' AS c_customer_id,
    NULL AS gender,
    NULL AS marital_status,
    NULL AS income_band,
    SUM(avg_spent) AS total_avg_spent,
    NULL AS total_returns
FROM 
    (
        SELECT 
            COALESCE(AVG(ws.ws_net_paid), 0) AS avg_spent
        FROM 
            web_sales ws 
        GROUP BY 
            ws.ws_bill_customer_sk
    ) AS agg;
