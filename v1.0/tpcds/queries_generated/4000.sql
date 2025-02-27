
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesMetrics AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk,
        d.cd_credit_rating,
        d.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        d.cd_credit_rating IS NOT NULL
),
DetailedAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ws.total_orders, 0) AS total_orders,
        COALESCE(ws.total_net_profit, 0) AS total_net_profit,
        COALESCE(ws.avg_net_paid, 0) AS avg_net_paid
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesMetrics ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    dda.cd_gender,
    dda.cd_marital_status,
    ib.ib_income_band_sk AS income_band,
    COUNT(*) AS customer_count,
    AVG(dda.total_return_quantity) AS avg_return_quantity,
    SUM(dda.total_net_profit) AS total_net_profit
FROM 
    DetailedAnalysis dda
JOIN 
    household_demographics hd ON dda.c_customer_sk = hd.hd_demo_sk
JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    (dda.total_orders > 10 OR dda.total_return_amt > 100)
GROUP BY 
    dda.cd_gender,
    dda.cd_marital_status,
    ib.ib_income_band_sk
HAVING 
    SUM(dda.total_return_quantity) > 5
ORDER BY 
    total_net_profit DESC
LIMIT 100;
