
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sales_price > 0
    GROUP BY ws_bill_customer_sk
),
SalesSummary AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        MAX(cs_ext_sales_price) AS max_order_value
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
),
CombinedSales AS (
    SELECT 
        coalesce(c.ws_bill_customer_sk, s.cs_bill_customer_sk) AS customer_sk,
        COALESCE(c.total_orders, 0) AS web_orders,
        COALESCE(s.total_orders, 0) AS catalog_orders,
        (COALESCE(c.total_profit, 0) + COALESCE(s.total_profit, 0)) AS combined_profit
    FROM CustomerSales c
    FULL OUTER JOIN SalesSummary s ON c.ws_bill_customer_sk = s.cs_bill_customer_sk
),
SummaryStatistics AS (
    SELECT 
        customer_sk,
        web_orders,
        catalog_orders,
        combined_profit,
        NTILE(3) OVER (ORDER BY combined_profit DESC) AS profit_band
    FROM CombinedSales
)
SELECT 
    cs.customer_sk,
    cs.web_orders,
    cs.catalog_orders,
    CASE 
        WHEN cs.combined_profit IS NULL THEN 'No Sales'
        WHEN cs.combined_profit < 100 THEN 'Low Profit'
        WHEN cs.combined_profit BETWEEN 100 AND 500 THEN 'Medium Profit'
        ELSE 'High Profit' 
    END AS profit_category,
    (SELECT AVG(sr_return_quantity) 
     FROM RankedReturns rr 
     WHERE rr.sr_item_sk IN (SELECT DISTINCT ws_item_sk 
                             FROM web_sales 
                             WHERE ws_bill_customer_sk = cs.customer_sk AND ws_sales_price IS NOT NULL)) AS avg_return_qty
FROM SummaryStatistics cs
WHERE cs.profit_band = 1 
  AND (cs.web_orders > 0 OR cs.catalog_orders > 0)
ORDER BY combined_profit DESC
LIMIT 10;
