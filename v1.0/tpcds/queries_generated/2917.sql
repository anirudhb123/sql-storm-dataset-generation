
WITH RankedReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
WebSalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.cd_gender,
    SUM(wss.total_sales) AS total_web_sales,
    SUM(rtr.total_return_quantity) AS total_returns,
    AVG(wss.total_net_profit) AS avg_net_profit
FROM 
    CustomerStats cs
JOIN 
    CustomerStats c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    WebSalesStats wss ON c.c_customer_sk = wss.ws_bill_customer_sk
LEFT JOIN 
    RankedReturns rtr ON rtr.sr_store_sk = (SELECT MIN(sr_store_sk) FROM store_returns)
WHERE 
    cs.total_returns > 0
GROUP BY 
    c.c_customer_id, cs.cd_gender
HAVING 
    SUM(wss.total_sales) > 1000 AND AVG(wss.total_net_profit) IS NOT NULL
ORDER BY 
    total_web_sales DESC
LIMIT 10;
