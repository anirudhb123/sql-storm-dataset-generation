
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(CASE WHEN sr_return_quantity IS NULL THEN 0 ELSE sr_return_quantity END) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
CustomerInformation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        COALESCE(ib.ib_income_band_sk, 999) AS income_band,
        COUNT(DISTINCT sr.ticket_number) AS total_returns
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender, cd.cd_credit_rating, ib.ib_income_band_sk
), 
SalesMetrics AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS sales_count,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(r.total_returned_quantity, 0) AS returns,
    COALESCE(sm.total_profit, 0) AS total_profit,
    sm.sales_count,
    ci.cd_marital_status,
    CASE 
        WHEN ci.cd_gender = 'F' THEN 'Female' 
        WHEN ci.cd_gender = 'M' THEN 'Male' 
        ELSE 'Other' 
    END AS gender,
    CASE 
        WHEN ci.total_returns > 5 THEN 'Frequent Returner'
        WHEN ci.total_returns BETWEEN 3 AND 5 THEN 'Moderate Returner'
        ELSE 'Occasional Returner'
    END AS return_behavior
FROM 
    CustomerInformation ci
LEFT JOIN 
    RankedReturns r ON ci.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    SalesMetrics sm ON r.sr_item_sk = sm.ws_item_sk
WHERE 
    (ci.cd_credit_rating IS NULL OR ci.cd_credit_rating NOT LIKE 'Excellent') 
    AND (sm.total_profit > 100 OR ci.return_behavior = 'Frequent Returner')
ORDER BY 
    ci.c_last_name, ci.c_first_name;
