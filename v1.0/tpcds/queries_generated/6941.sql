
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
IncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    c.c_customer_id,
    cr.total_returned,
    cr.total_return_amount,
    i.total_sales,
    i.avg_net_profit,
    d.ib_lower_bound,
    d.ib_upper_bound,
    d.avg_vehicle_count
FROM 
    CustomerReturns cr
JOIN 
    customer c ON cr.c_customer_sk = c.c_customer_sk
JOIN 
    ItemSales i ON i.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cr.c_customer_sk LIMIT 1)
JOIN 
    IncomeDemographics d ON d.hd_demo_sk = c.c_current_hdemo_sk
WHERE 
    cr.total_returned > 0
ORDER BY 
    cr.total_return_amount DESC, 
    i.avg_net_profit DESC
LIMIT 10;
