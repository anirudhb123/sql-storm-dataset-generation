
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(sr.sr_ticket_number) AS total_store_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
), 
WebSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_sales_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), 
CustomerIncomeDemographics AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_band
    FROM 
        household_demographics h
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cr.c_customer_id,
    COALESCE(cr.total_store_returns, 0) AS store_returns_count,
    COALESCE(cr.total_return_quantity, 0) AS store_return_quantity,
    COALESCE(cr.total_return_amount, 0) AS store_return_total_amount,
    COALESCE(ws.total_web_sales_profit, 0) AS web_sales_profit,
    cid.income_band
FROM 
    CustomerReturns cr
FULL OUTER JOIN 
    WebSales ws ON cr.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c 
        WHERE c.c_customer_sk = ws.ws_bill_customer_sk
        LIMIT 1
    )
LEFT JOIN 
    CustomerIncomeDemographics cid ON cr.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c 
        WHERE c.c_customer_sk = cid.hd_demo_sk
        LIMIT 1
    )
WHERE 
    (cr.total_store_returns IS NOT NULL OR ws.total_web_sales_profit IS NOT NULL)
ORDER BY 
    store_returns_count DESC, web_sales_profit DESC
LIMIT 100;
