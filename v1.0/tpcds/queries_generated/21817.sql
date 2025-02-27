
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS TotalNetProfit,
        COUNT(ss.ss_ticket_number) AS TotalSalesCount
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
SubqueryIncome AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS GenderCount,
        MAX(cd.cd_purchase_estimate) AS MaxPurchaseEstimate
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ca.ca_city,
    COALESCE(ss.TotalNetProfit, 0) AS StoreNetProfit,
    COALESCE(rs.ProfitRank, 0) AS WebSalesProfitRank,
    di.d_year AS SalesYear,
    SUM(CASE 
            WHEN ws.ws_quantity > 5 THEN ws.ws_net_profit 
            ELSE 0 
        END) AS HighQuantityProfit,
    (SELECT COUNT(*) FROM customer c WHERE c.c_birth_month = 5 AND c.c_birth_year IS NOT NULL) AS MayBirthCount,
    (SELECT MAX(s.TotalSalesCount)
     FROM StoreSalesSummary s
     WHERE s.TotalNetProfit > 1000) AS MaxStoreSalesCount
FROM 
    customer_address ca
LEFT JOIN 
    store_sales ss ON ca.ca_address_sk = ss.ss_addr_sk
LEFT JOIN 
    RankedSales rs ON ss.ss_item_sk = rs.ws_item_sk
JOIN 
    date_dim di ON di.d_date_sk = ss.ss_sold_date_sk
LEFT JOIN 
    SubqueryIncome si ON si.MaxPurchaseEstimate > 1000
WHERE 
    ca.ca_state = 'CA' 
    AND (ss.ss_sales_price < 50 OR ss.ss_sales_price IS NULL)
    AND (rs.ProfitRank = 1 OR rs.ws_item_sk IS NULL)
GROUP BY 
    ca.ca_city, di.d_year, ss.TotalNetProfit, rs.ProfitRank
HAVING 
    SUM(ss.ss_quantity) > 100
ORDER BY 
    StoreNetProfit DESC, WebSalesProfitRank ASC;
