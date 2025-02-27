
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.item_sk, 
        sr.return_quantity, 
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk, sr.returned_date_sk ORDER BY sr.return_quantity DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
TopReturns AS (
    SELECT 
        item_sk, 
        SUM(return_quantity) AS total_returned
    FROM 
        RankedReturns
    WHERE 
        rn = 1
    GROUP BY 
        item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ss.ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
SalesWithReturns AS (
    SELECT 
        cs.item_sk,
        cs.total_sales,
        COALESCE(tr.total_returned, 0) AS total_returned,
        cs.total_sales - COALESCE(tr.total_returned, 0) AS net_sales
    FROM 
        (SELECT 
             ws.item_sk, 
             COUNT(ws.ws_order_number) AS total_sales 
         FROM 
             web_sales ws 
         GROUP BY 
             ws.item_sk) cs
    LEFT JOIN 
        TopReturns tr ON cs.item_sk = tr.item_sk
)
SELECT 
    s.item_sk,
    s.total_sales,
    s.total_returned,
    s.net_sales,
    cs.avg_purchase_estimate,
    cs.total_profit
FROM 
    SalesWithReturns s
JOIN 
    CustomerStats cs ON cs.total_sales > 0
WHERE 
    (s.net_sales > 0 OR s.total_returned IS NOT NULL)
    AND (s.total_sales + COALESCE(s.total_returned, 0)) > 10
ORDER BY 
    net_sales DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM CustomerStats) / 2;

