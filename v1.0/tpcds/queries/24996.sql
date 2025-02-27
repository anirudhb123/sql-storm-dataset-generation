
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
PotentialLoss AS (
    SELECT 
        ws.ws_item_sk,
        COALESCE(SUM(sr.total_returned), 0) AS derived_returned,
        COALESCE(SUM(sr.total_return_amount), 0) AS derived_return_amount
    FROM 
        RankedSales ws
    LEFT JOIN 
        AggregateReturns sr ON ws.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_net_profit) > COALESCE(SUM(sr.total_return_amount), 0)
)
SELECT 
    p.ws_item_sk,
    p.derived_returned,
    p.derived_return_amount,
    CASE 
        WHEN (p.derived_returned / NULLIF(SUM(r.ws_quantity), 0)) > 0.5 THEN 'High Risk' 
        ELSE 'Regular'
    END AS risk_category
FROM 
    PotentialLoss p
JOIN 
    RankedSales r ON p.ws_item_sk = r.ws_item_sk
WHERE 
    EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk IN (
            SELECT DISTINCT sr_customer_sk 
            FROM store_returns 
            WHERE sr_item_sk = p.ws_item_sk 
            AND sr_return_quantity IS NOT NULL
        )
    )
GROUP BY 
    p.ws_item_sk, 
    p.derived_returned, 
    p.derived_return_amount
ORDER BY 
    p.derived_returned DESC, 
    risk_category ASC;
