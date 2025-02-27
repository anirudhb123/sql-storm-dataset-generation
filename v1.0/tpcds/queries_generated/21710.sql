
WITH RECURSIVE IncomeBreakdown AS (
    SELECT 
        ib_income_band_sk, 
        ib_lower_bound, 
        ib_upper_bound,
        CASE 
            WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Undefined Range'
            ELSE CONCAT('Income Range: ', ib_lower_bound, ' - ', ib_upper_bound)
        END AS income_range,
        1 AS level
    FROM 
        income_band
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CONCAT('Level ', level + 1, ': ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound) AS income_range,
        level + 1
    FROM 
        income_band ib
    JOIN IncomeBreakdown ibd ON ib.ib_income_band_sk = ibd.ib_income_band_sk AND level < 5
),
CustomerAnalytics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT web.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
TotalReturns AS (
    SELECT 
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr_order_number) AS total_catalog_returns,
        COUNT(DISTINCT wr_order_number) AS total_web_returns
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        catalog_returns cr ON sr.sr_ticket_number = cr.cr_order_number
    FULL OUTER JOIN 
        web_returns wr ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
),
FinalReport AS (
    SELECT 
        ca.c_customer_sk,
        ca.cd_gender,
        ca.cd_marital_status,
        ib.income_range,
        ca.order_count,
        ca.total_spent,
        ca.last_purchase_date,
        COALESCE(tr.total_store_returns, 0) AS total_store_returns,
        COALESCE(tr.total_catalog_returns, 0) AS total_catalog_returns,
        COALESCE(tr.total_web_returns, 0) AS total_web_returns
    FROM 
        CustomerAnalytics ca
    LEFT JOIN 
        IncomeBreakdown ib ON ca.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        TotalReturns tr ON tr.total_store_returns IS NOT NULL OR tr.total_catalog_returns IS NOT NULL OR tr.total_web_returns IS NOT NULL
)
SELECT 
    c.c_customer_id,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.total_spent, 0) AS total_spent,
    f.last_purchase_date,
    f.income_range,
    CASE 
        WHEN f.order_count = 0 THEN 'No Purchases'
        WHEN f.total_spent > 2000 THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    FinalReport f
JOIN 
    customer c ON f.c_customer_sk = c.c_customer_sk
WHERE 
    f.last_purchase_date IS NOT NULL AND f.total_spent IS NOT NULL
ORDER BY 
    f.total_spent DESC, f.last_purchase_date DESC
LIMIT 100 OFFSET 10;
