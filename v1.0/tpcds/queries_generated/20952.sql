
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
), 
WeightedDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        POWER(cd_dep_count + 1, 2) * 
        CASE WHEN cd_credit_rating = 'Excellent' THEN 1.5 
             WHEN cd_credit_rating = 'Good' THEN 1.2 
             WHEN cd_credit_rating = 'Poor' THEN 0.8 
             ELSE 1 END AS weighted_estimate
    FROM 
        customer_demographics
), 
SalesWithDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        COALESCE(sm.sm_type, 'Unknown') AS shipping_method,
        ws.ws_quantity,
        CASE 
            WHEN ws.ws_net_profit IS NULL THEN 0 
            ELSE ws.ws_net_profit 
        END AS safe_profit
    FROM 
        web_sales ws
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
), 
TotalSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cd.weighted_estimate) AS total_weighted_estimated,
    COALESCE(SUM(cr.return_count), 0) AS total_return_count,
    COALESCE(SUM(cr.total_return_amount), 0) AS total_return_value,
    SUM(sd.total_store_sales) AS total_retail_sales,
    AVG(sd.total_store_profit) AS average_profit_per_store,
    STRING_AGG(DISTINCT swd.shipping_method, ', ') AS shipping_methods
FROM 
    WeightedDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.cd_demo_sk = cr.sr_customer_sk
LEFT JOIN 
    SalesWithDetails swd ON swd.ws_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = cr.sr_customer_sk)
LEFT JOIN 
    TotalSales sd ON sd.ss_store_sk IN (SELECT ss_store_sk FROM store WHERE s_country IS NOT NULL)
WHERE 
    cd.cd_purchase_estimate IS NOT NULL
GROUP BY 
    cd.cd_gender,
    cd.cd_marital_status
HAVING 
    SUM(cd.weighted_estimate) > 100
ORDER BY 
    total_weighted_estimated DESC, 
    total_return_value ASC;
