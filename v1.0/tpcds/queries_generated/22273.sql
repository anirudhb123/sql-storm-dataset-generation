
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 0
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
SalesData AS (
    SELECT 
        ws.ws_billing_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_billing_customer_sk
), 
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS average_paid,
        SUM(CASE WHEN ws.ws_quantity < 0 THEN ws.ws_quantity ELSE 0 END) AS total_negative_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    GROUP BY 
        i.i_item_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(cd.buy_potential, 'No Data') AS customer_buy_potential,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(sd.total_profit, 0.00) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(isummary.average_paid, 0.00) AS average_paid,
    CASE 
        WHEN cr.return_count > 5 THEN 'Frequent Returner' 
        WHEN cr.total_returns > 10 THEN 'High Returner' 
        ELSE 'Low Returner' 
    END AS return_type
FROM 
    customer c 
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_billing_customer_sk
LEFT JOIN 
    ItemSummary isummary ON isummary.order_count > 5 
WHERE 
    cd.cd_gender = 'F' 
    AND (cd.cd_purchase_estimate IS NOT NULL OR cd.cd_credit_rating IS NOT NULL)
ORDER BY 
    total_profit DESC, c.c_first_name ASC 
LIMIT 100;
