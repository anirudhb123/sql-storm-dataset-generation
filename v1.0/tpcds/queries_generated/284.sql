
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 ORDER BY d_date_sk DESC LIMIT 1)
),
StoreSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS TotalNetProfit,
        COUNT(DISTINCT ss.ss_order_number) AS TotalOrders
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 ORDER BY d_date_sk DESC LIMIT 1)
    GROUP BY 
        ss.ss_store_sk
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(ss.TotalNetProfit, 0) AS NetProfit,
        ss.TotalOrders,
        RANK() OVER (ORDER BY COALESCE(ss.TotalNetProfit, 0) DESC) AS ProfitRank
    FROM 
        store s
    LEFT JOIN 
        StoreSummary ss ON s.s_store_sk = ss.ss_store_sk
),
SalesReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        SUM(sr_return_amt) AS TotalReturnAmt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 6 ORDER BY d_date_sk DESC LIMIT 1)
    GROUP BY 
        sr_item_sk
)
SELECT 
    ts.s_store_name,
    ts.NetProfit,
    ts.TotalOrders,
    COALESCE(rs.TotalReturns, 0) AS ItemReturns,
    COALESCE(rs.TotalReturnAmt, 0) AS ReturnAmount,
    AVG(rs.TotalReturnAmt) OVER (PARTITION BY ts.ProfitRank) AS AvgReturnAmt,
    AVG(ws.ws_net_profit) OVER (PARTITION BY rs.TotalReturns ORDER BY ws.ws_net_profit DESC) AS AvgNetProfitPerReturn
FROM 
    TopStores ts
LEFT JOIN 
    SalesReturns rs ON ts.s_store_sk = rs.sr_item_sk
JOIN 
    RankedSales ws ON rs.sr_item_sk = ws.ws_item_sk
WHERE 
    ts.ProfitRank <= 10
ORDER BY 
    ts.NetProfit DESC, ts.TotalOrders DESC;
