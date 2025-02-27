
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity
    FROM 
        customer c
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
), 
SalesPerformance AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
), 
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_credit_rating,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        COALESCE(sp.total_net_profit, 0) AS total_net_profit,
        COALESCE(sp.total_orders, 0) AS total_orders,
        COALESCE(sp.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ci.total_returns, 0) AS total_returns,
        COALESCE(ci.total_return_amount, 0) AS total_return_amount,
        COALESCE(ci.avg_return_quantity, 0) AS avg_return_quantity
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesPerformance sp ON ci.c_customer_sk = sp.ws_ship_customer_sk
)

SELECT 
    * 
FROM 
    FinalReport
WHERE 
    (total_net_profit > 1000 OR total_returns > 5)
    AND (cd_gender = 'F' OR cd_marital_status = 'M')
ORDER BY 
    total_net_profit DESC, 
    total_returns DESC;
