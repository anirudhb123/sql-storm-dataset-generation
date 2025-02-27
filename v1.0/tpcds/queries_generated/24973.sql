
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SaleRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        AVG(sr_return_amt) AS avg_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_amt > 0 AND sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
CrossSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        COALESCE(hb.total_return_qty, 0) AS total_return_qty
    FROM 
        web_sales ws
    LEFT JOIN 
        HighValueReturns hb ON ws.ws_item_sk = hb.sr_item_sk
),
FilteredSales AS (
    SELECT 
        cs.ws_order_number,
        cs.ws_item_sk,
        cs.net_profit,
        cs.total_return_qty,
        CASE 
            WHEN cs.total_return_qty IS NULL THEN 'No Returns'
            WHEN cs.total_return_qty > 0 AND cs.net_profit > 100 THEN 'High Risk'
            ELSE 'Low Risk'
        END AS risk_category
    FROM 
        CrossSales cs
    WHERE 
        cs.net_profit > (SELECT AVG(net_profit) FROM CrossSales) 
        AND cs.total_return_qty < (SELECT AVG(total_return_qty) FROM HighValueReturns)
)
SELECT 
    c.c_customer_sk,
    cd_gender,
    cd_marital_status,
    SUM(f.net_profit) AS total_profit,
    COUNT(DISTINCT f.ws_order_number) AS total_orders,
    MAX(f.risk_category) AS risk_category
FROM 
    FilteredSales f
JOIN 
    CustomerDemographics c ON f.ws_order_number = c.c_customer_sk 
WHERE 
    c.cd_gender IN ('M', 'F') 
    AND c.cd_marital_status IS NOT NULL
GROUP BY 
    c.c_customer_sk, 
    cd_gender, 
    cd_marital_status 
HAVING 
    SUM(f.net_profit) > (SELECT AVG(total_profit) FROM FilteredSales)
ORDER BY 
    total_profit DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
