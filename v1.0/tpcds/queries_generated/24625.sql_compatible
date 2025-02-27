
WITH RECURSIVE IncomeEstimation AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 0
            WHEN cd_marital_status = 'M' AND cd_dep_count > 0 THEN cd_purchase_estimate * 1.2
            WHEN cd_gender = 'F' AND cd_dep_college_count > 0 THEN cd_purchase_estimate * 1.1
            ELSE cd_purchase_estimate
        END AS estimated_purchase
    FROM 
        customer_demographics 
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
SeasonalSales AS (
    SELECT 
        dt.d_year, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY dt.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS year_rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim dt ON ws.ws_sold_date_sk = dt.d_date_sk
    GROUP BY 
        dt.d_year
),
StorePerformance AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_store_profit,
        AVG(ss.ss_sales_price) AS avg_item_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM 
        store s 
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk 
    GROUP BY 
        s.s_store_id
),
ItemReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_id,
        SUM(ie.estimated_purchase) AS total_estimated_purchase,
        sp.total_store_profit,
        ss.total_net_profit,
        ir.total_returns
    FROM 
        customer ci
    LEFT JOIN 
        IncomeEstimation ie ON ci.c_current_cdemo_sk = ie.cd_demo_sk
    LEFT JOIN 
        StorePerformance sp ON ci.c_current_addr_sk = sp.s_store_id 
    LEFT JOIN 
        SeasonalSales ss ON ci.c_current_hdemo_sk = ss.d_year 
    LEFT JOIN 
        ItemReturns ir ON ci.c_customer_sk = ir.cr_item_sk
    WHERE 
        ci.c_birth_year IS NOT NULL AND 
        (ir.total_returns IS NULL OR ir.total_returns <= 3)
    GROUP BY 
        ci.c_customer_id, sp.total_store_profit, ss.total_net_profit, ir.total_returns
)
SELECT 
    *,
    CASE 
        WHEN total_estimated_purchase IS NULL THEN 'Not Estimated'
        WHEN total_store_profit > total_net_profit THEN 'Profitable Store'
        ELSE 'Check Performance'
    END AS performance_status
FROM 
    FinalReport
ORDER BY 
    total_estimated_purchase DESC, c_customer_id;
