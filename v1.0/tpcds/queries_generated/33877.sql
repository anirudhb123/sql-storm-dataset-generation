
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_quantity) > 100
), 
High_Profit_Items AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM Sales_CTE
    WHERE rank = 1
), 
Customer_Income AS (
    SELECT 
        cd_demo_sk, 
        hd_income_band_sk,
        SUM(cd_purchase_estimate) AS total_estimate
    FROM customer_demographics
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY cd_demo_sk, hd_income_band_sk
)
SELECT 
    ca.city,
    w.warehouse_name,
    SUM(CASE WHEN hi.profit_rank <= 5 THEN hi.total_profit ELSE 0 END) AS top_5_profit,
    SUM(CASE WHEN hi.profit_rank > 5 THEN hi.total_profit ELSE 0 END) AS other_profit,
    COUNT(DISTINCT ci.cd_demo_sk) AS customer_count
FROM High_Profit_Items hi
JOIN inventory inv ON hi.ws_item_sk = inv.inv_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON w.w_warehouse_sk = ca.ca_address_sk
JOIN Customer_Income ci ON ci.hd_income_band_sk IN (1, 2, 3)
GROUP BY ca.city, w.warehouse_name
HAVING COUNT(DISTINCT hi.ws_item_sk) > 10
ORDER BY top_5_profit DESC, city ASC
