
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ws_item_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales s
    JOIN 
        web_sales w ON s.ss_item_sk = w.ws_item_sk
    GROUP BY 
        ss_store_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL OR cd.cd_gender IS NOT NULL
)
SELECT 
    cd.gender AS customer_gender,
    cd.marital_status,
    COUNT(DISTINCT cr.sr_returning_customer_sk) AS number_of_returning_customers,
    AVG(cr.total_return_amount) AS avg_return_amount,
    SUM(rs.total_net_profit) AS total_profit,
    AVG(rs.total_net_profit) AS avg_profit_per_store
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    RankedSales rs ON cd.c_customer_sk IN (SELECT distinct ws_bill_customer_sk FROM web_sales WHERE ws_ship_customer_sk IS NOT NULL)
GROUP BY 
    cd.gender, cd.marital_status
HAVING 
    SUM(CASE WHEN cr.total_returns IS NULL THEN 0 ELSE cr.total_returns END) > 0
ORDER BY 
    total_profit DESC, customer_gender DESC;
