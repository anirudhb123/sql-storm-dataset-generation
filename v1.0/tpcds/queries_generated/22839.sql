
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        cs.cs_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS RankByProfit,
        SUM(ws.ws_net_profit) AS TotalProfit
    FROM 
        web_sales ws
    JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        ws.web_site_sk, cs.cs_item_sk
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT CASE WHEN c.c_current_addr_sk IS NOT NULL THEN c.c_customer_sk END) AS ActiveCustomers,
        AVG(cd.cd_purchase_estimate) AS AveragePurchaseEstimate,
        COUNT(CASE WHEN cd.cd_gender = 'F' THEN 1 END) AS FemaleCount,
        COUNT(CASE WHEN cd.cd_gender = 'M' THEN 1 END) AS MaleCount
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
ReturnMetrics AS (
    SELECT 
        sr.returned_date, 
        SUM(sr.return_quantity) AS TotalReturns,
        AVG(sr.return_amt) FILTER (WHERE sr.return_amt IS NOT NULL) AS AverageReturnAmt
    FROM 
        store_returns sr
    LEFT JOIN 
        date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    GROUP BY 
        sr.returned_date
)

SELECT 
    w.w_warehouse_id,
    MAX(RS.TotalProfit) AS MaxTotalProfit,
    AVG(CS.AveragePurchaseEstimate) AS OverallAveragePurchase,
    RANK() OVER (ORDER BY MAX(RS.TotalProfit) DESC) AS ProfitRank,
    COALESCE(RM.AverageReturnAmt, 0) AS AverageReturnAmount,
    RS.web_site_sk
FROM 
    RankedSales RS
JOIN 
    warehouse w ON RS.web_site_sk = w.w_warehouse_sk 
LEFT JOIN 
    CustomerStats CS ON w.w_warehouse_sk = CS.cd_demo_sk
LEFT JOIN 
    ReturnMetrics RM ON RM.returned_date <= CURRENT_DATE 
GROUP BY
    w.w_warehouse_id, RS.web_site_sk
HAVING 
    MAX(RS.TotalProfit) > (SELECT AVG(TotalProfit) FROM RankedSales)
ORDER BY 
    ProfitRank
LIMIT 10;
