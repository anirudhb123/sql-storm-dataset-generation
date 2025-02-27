
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS returns_count
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
IncomeDemographics AS (
    SELECT 
        hd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN hd_buy_potential IS NOT NULL THEN 1 ELSE 0 END) AS potential_buyers
    FROM 
        household_demographics hd
    LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd_demo_sk
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(COALESCE(ws.net_profit, 0)) AS promo_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        promotion p 
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
TotalReturns AS (
    SELECT 
        cr.refunded_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.refunded_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(COALESCE(cr.total_returned_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(cr.total_returned_amount, 0)) AS total_return_amount,
    SUM(COALESCE(id.customer_count, 0)) AS customer_count,
    COUNT(DISTINCT COALESCE(p.p_promo_id, 'No Promo')) AS promo_count,
    AVG(p.promo_net_profit) AS average_promo_profit
FROM 
    customer_demographics cd
LEFT JOIN CustomerReturns cr ON cd.cd_demo_sk = cr.sr_customer_sk
LEFT JOIN IncomeDemographics id ON cd.cd_demo_sk = id.hd_demo_sk
LEFT JOIN Promotions p ON p.promo_net_profit > 1000
WHERE 
    (cd.cd_marital_status = 'M' AND cd.cd_gender = 'F')
    OR (cd.cd_marital_status = 'S' AND NOT EXISTS (SELECT 1 FROM store WHERE s_store_name IS NULL))
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(COALESCE(cr.total_returned_quantity, 0)) > 5
    AND AVG(p.promo_net_profit) IS NOT NULL
ORDER BY 
    total_return_amount DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
