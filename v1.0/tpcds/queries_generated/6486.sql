
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns,
        AVG(sr_return_amt) AS avg_return_amt
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
PromotionStats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
), 
AvgIncomeByDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)

SELECT 
    c.c_customer_id,
    cr.total_returned_qty,
    cr.total_returned_amt,
    cr.unique_returns,
    cr.avg_return_amt,
    p.promo_count,
    p.total_net_profit,
    di.avg_income_band
FROM 
    customer c
LEFT JOIN 
    CustomerReturnStats cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN 
    (SELECT 
        p.p_promo_id,
        COUNT(s.ws_order_number) AS promo_count,
        SUM(s.ws_net_profit) AS total_net_profit
     FROM 
        promotion p
     JOIN 
        web_sales s ON p.p_promo_sk = s.ws_promo_sk
     GROUP BY 
        p.p_promo_sk) AS p ON p.p_promo_id = (SELECT p.p_promo_id FROM promotion p ORDER BY RAND() LIMIT 1)
LEFT JOIN 
    AvgIncomeByDemographics di ON c.c_current_cdemo_sk = di.cd_demo_sk
WHERE 
    cr.total_returned_qty > 0
AND 
    di.avg_income_band IS NOT NULL
ORDER BY 
    cr.total_returned_amt DESC
LIMIT 100;
