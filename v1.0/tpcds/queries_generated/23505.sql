
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rank_return
    FROM 
        catalog_returns 
    GROUP BY 
        cr_returning_customer_sk
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns,
        COLUMNS_AMOUNT = COALESCE(NULLIF(SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT CONCAT_ws(' ', c.c_first_name, c.c_last_name)), ' ', 1), ''), 'N/A'),
        c.c_preferred_cust_flag,
        CASE 
            WHEN cr.total_returns IS NULL THEN 'NO RETURNS'
            WHEN cr.total_returns > 5 THEN 'FREQUENT RETURNER'
            ELSE 'RARE RETURNER'
        END AS return_behavior
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE 
        c.c_birth_month IN (1, 2, 12) 
        AND (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_gender = 'F') > 0
    GROUP BY 
        c.c_customer_id, cr.total_returns, c.c_preferred_cust_flag
),
ShipModesData AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        ship_mode sm
    LEFT JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cr.c_customer_id,
    cr.total_returns,
    cr.COLUMNS_AMOUNT,
    cr.c_preferred_cust_flag,
    cr.return_behavior,
    smd.sm_ship_mode_id,
    smd.order_count,
    COALESCE(NULLIF(smd.avg_profit, 0), -1) AS adjusted_avg_profit
FROM 
    CustomerReturns cr
FULL OUTER JOIN 
    ShipModesData smd ON cr.return_behavior = 'FREQUENT RETURNER'
WHERE 
    COALESCE(cr.total_returns, 0) >= 0 
    AND COALESCE(smd.order_count, 0) > 0
ORDER BY 
    cr.total_returns DESC NULLS LAST,
    smd.order_count DESC;
