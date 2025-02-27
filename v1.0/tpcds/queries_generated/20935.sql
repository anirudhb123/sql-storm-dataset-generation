
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        sr_return_time_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_time_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
RecentReturns AS (
    SELECT 
        rr.sr_returning_customer_sk,
        rr.sr_return_time_sk,
        COALESCE((
            SELECT 
                SUM(ws_net_profit)
            FROM 
                web_sales ws
            WHERE 
                ws.ws_ship_customer_sk = rr.sr_returning_customer_sk
                AND ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 10)
                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 10 AND d_dow IN (5, 6))
        ), 0) AS total_web_profit
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn = 1
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND c.c_birth_month IS NOT NULL
        AND c.c_birth_day IS NOT NULL
)
SELECT 
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(r.total_web_profit, 0) AS total_recent_web_profit,
    COUNT(r.sr_returning_customer_sk) AS recent_return_count,
    CASE 
        WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
        ELSE cd.cd_credit_rating
    END AS credit_rating,
    CASE 
        WHEN (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_customer_sk = cd.cd_demo_sk) > 10 THEN 'Frequent Visitor'
        ELSE 'Rare Visitor'
    END AS visitation_frequency
FROM 
    CustomerDemographics cd
LEFT JOIN 
    RecentReturns r ON r.sr_returning_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, r.total_web_profit, cd.cd_credit_rating
HAVING 
    COUNT(r.sr_returning_customer_sk) > 1
ORDER BY 
    total_recent_web_profit DESC, cd.cd_gender ASC;
