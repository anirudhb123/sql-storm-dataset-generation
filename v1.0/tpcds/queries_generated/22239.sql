
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS RankSale,
        ws_net_profit
    FROM web_sales
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS TotalNetProfit
    FROM RankedSales rs
    WHERE rs.RankSale = 1
    GROUP BY rs.ws_item_sk
    HAVING SUM(rs.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales WHERE ws_sales_price > 100)
),
ItemDetails AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc,
        CASE 
            WHEN iv.inv_quantity_on_hand IS NULL THEN 0
            ELSE iv.inv_quantity_on_hand
        END AS AvailableStock,
        COALESCE(ib.ib_upper_bound, 99999) AS UpperIncomeBound
    FROM item i
    LEFT JOIN inventory iv ON i.i_item_sk = iv.inv_item_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = (SELECT MIN(hd_demo_sk) FROM household_demographics)
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    HPI.TotalNetProfit,
    id.AvailableStock,
    CASE 
        WHEN id.AvailableStock = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS StockStatus,
    RANK() OVER (ORDER BY HPI.TotalNetProfit DESC) AS ProfitRank
FROM ItemDetails id
JOIN HighProfitItems HPI ON id.i_item_sk = HPI.ws_item_sk
WHERE id.UpperIncomeBound BETWEEN 1000 AND 5000
UNION ALL
SELECT 
    'Total' AS i_item_id, 
    NULL AS i_item_desc, 
    SUM(HPI.TotalNetProfit) AS TotalNetProfit, 
    NULL AS AvailableStock,
    NULL AS StockStatus,
    NULL AS ProfitRank
FROM HighProfitItems HPI;
