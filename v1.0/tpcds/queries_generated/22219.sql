
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS ReturnRank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
        AND sr_return_amt >= 0
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(sr.return_quantity) AS TotalReturns,
        CASE 
            WHEN SUM(sr.return_quantity) IS NULL THEN 'No Returns'
            WHEN SUM(sr.return_quantity) > 5 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS ReturnerType
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        RankedReturns sr ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS CustomerSK,
        SUM(ws_net_profit) AS TotalProfit,
        COUNT(DISTINCT ws_order_number) AS TotalOrders,
        SUM(CASE WHEN ws_ext_discount_amt > 0 THEN 1 ELSE 0 END) AS DiscountedOrders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AggregateData AS (
    SELECT 
        cd.c_customer_id,
        SUM(COALESCE(ss.TotalProfit, 0)) AS CustomerTotalProfit,
        MAX(cd.ReturnerType) AS ReturnerCategory,
        STRING_AGG(DISTINCT CASE WHEN cd.TotalReturns IS NOT NULL THEN 'Returns:' || cd.TotalReturns ELSE 'No Returns' END, ', ') AS ReturnsSummary
    FROM 
        CustomerDetails cd
    FULL OUTER JOIN 
        SalesSummary ss ON cd.c_customer_id = ss.CustomerSK
    GROUP BY 
        cd.c_customer_id
)
SELECT 
    ad.c_customer_id,
    ad.CustomerTotalProfit,
    ad.ReturnerCategory,
    ad.ReturnsSummary
FROM 
    AggregateData ad
WHERE 
    (ad.CustomerTotalProfit > 1000 OR ad.ReturnerCategory = 'Frequent Returner')
    AND (ad.ReturnSummary IS NOT NULL AND ad.CustomerTotalProfit IS NOT NULL)
ORDER BY 
    ad.CustomerTotalProfit DESC NULLS LAST;
