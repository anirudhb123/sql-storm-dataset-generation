
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        COALESCE(ws.ws_coupon_amt, 0) AS coupon,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS recent_sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_tax IS NOT NULL
),
StorePerformance AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_ext_sales_price) AS avg_sales_price
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
),
IncomeBandAnalysis AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        hd.hd_buy_potential IS NOT NULL 
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    sp.s_store_id,
    sp.total_profit,
    sp.total_sales,
    sp.avg_sales_price,
    ia.customer_count,
    ROW_NUMBER() OVER (PARTITION BY rc.cd_gender ORDER BY sp.total_profit DESC) AS store_rank_within_gender,
    CASE 
        WHEN rc.rank_by_purchase <= 5 AND sp.total_sales > 100 THEN 'Top Purchaser and High Sales'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    RankedCustomers rc
JOIN 
    StorePerformance sp ON rc.c_customer_id = sp.s_store_id 
FULL OUTER JOIN 
    IncomeBandAnalysis ia ON rc.cd_credit_rating = ia.ib_income_band_sk
WHERE 
    sp.total_profit IS NOT NULL 
    OR ia.customer_count IS NOT NULL
ORDER BY 
    rc.cd_gender, sp.total_profit DESC;
