
WITH RankedReturns AS (
    SELECT 
        cr.refunded_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY cr.refunded_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rn
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.refunded_customer_sk
), CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        (SELECT AVG(cd_purchase_estimate)
         FROM customer_demographics 
         WHERE cd_credit_rating IS NOT NULL) AS average_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS web_sales_profit
    FROM 
        catalog_sales cs
    LEFT JOIN 
        web_sales ws ON cs.cs_item_sk = ws.ws_item_sk
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    CASE 
        WHEN r.total_returned IS NULL THEN 'No Returns'
        ELSE CAST(r.total_returned AS VARCHAR) || ' Items Returned'
    END AS return_info,
    sd.total_net_profit,
    sd.order_count,
    sd.web_sales_profit,
    CASE 
        WHEN sd.total_net_profit IS NULL THEN 0 
        ELSE (sd.total_net_profit / NULLIF(sd.order_count, 0))
    END AS avg_profit_per_order
FROM 
    CustomerIncome ci
LEFT JOIN 
    RankedReturns r ON ci.c_customer_sk = r.refunded_customer_sk AND r.rn = 1
JOIN 
    SalesData sd ON ci.c_customer_sk = sd.cs_item_sk
WHERE 
    (ci.ib_lower_bound < 50000 OR ci.ib_upper_bound IS NULL)
    AND ci.cd_marital_status IN ('M', 'S')
ORDER BY 
    sd.total_net_profit DESC, ci.cd_gender ASC
LIMIT 100;
