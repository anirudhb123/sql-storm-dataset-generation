
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_department,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    WHERE 
        ws.ws_net_paid > 0 OR ws.ws_net_paid_inc_tax > 0
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
FilteredCTE AS (
    SELECT 
        r.*, 
        ROW_NUMBER() OVER (PARTITION BY r.gender_rank ORDER BY r.total_profit DESC) AS rank_within_group
    FROM 
        RecursiveCTE r
    WHERE 
        r.total_profit IS NOT NULL AND r.gender_rank <= 5
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.total_profit,
    COALESCE((
        SELECT 
            SUM(sr_return_amt) 
        FROM 
            store_returns sr 
        WHERE 
            sr.sr_customer_sk = f.c_customer_sk
            AND sr_return_quantity > 0
    ), 0) AS total_returns,
    CASE 
        WHEN f.total_profit IS NULL THEN 'Not Available'
        WHEN f.total_profit < 1000 THEN 'Low Profit'
        WHEN f.total_profit BETWEEN 1000 AND 5000 THEN 'Medium Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    FilteredCTE f
WHERE 
    f.rank_within_group = 1
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    NULL AS c_first_name,
    'Aggregate' AS c_last_name,
    NULL AS cd_gender,
    NULL AS total_profit,
    NULL AS total_returns,
    'N/A' AS profit_category
ORDER BY 
    profit_category DESC, total_profit DESC;
