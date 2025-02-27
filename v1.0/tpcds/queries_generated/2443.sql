
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
CustomerPurchaseStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.bill_customer_sk) AS customer_count,
        SUM(cs.net_profit) AS total_profit,
        AVG(cs.net_profit) AS avg_profit
    FROM 
        catalog_sales cs
    JOIN 
        customer_demographics cd ON cs.bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cd.cd_gender
),
ReturnAnalysis AS (
    SELECT 
        rr.customer_sk,
        COUNT(DISTINCT wr.return_order_number) AS return_count,
        SUM(wr.return_amt) AS total_return_amt,
        AVG(wr.return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    LEFT JOIN 
        (SELECT DISTINCT wr_returning_customer_sk AS customer_sk FROM web_returns) rr ON rr.customer_sk = wr.returning_customer_sk
    GROUP BY 
        rr.customer_sk
)
SELECT 
    cps.cd_gender,
    cps.customer_count,
    cps.total_profit,
    cps.avg_profit,
    ra.return_count,
    ra.total_return_amt,
    ra.avg_return_amt
FROM 
    CustomerPurchaseStats cps
LEFT JOIN 
    ReturnAnalysis ra ON cps.customer_count = ra.return_count
WHERE 
    cps.customer_count > 100
ORDER BY 
    cps.total_profit DESC, 
    cps.customer_count DESC 
LIMIT 100;
