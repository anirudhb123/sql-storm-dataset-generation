
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price
    FROM RankedSales rs
    WHERE rs.rnk <= 3
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.cs_order_number) AS "Store Catalog Sales",
    SUM(cs.cs_net_profit) AS "Total Catalog Profit",
    COALESCE(SUM(ws.ws_net_profit), 0) AS "Web Sales Profit",
    AVG(TOP_SALES.ws_ext_sales_price) AS "Average Top Sales Price"
FROM customer_address ca
JOIN store s ON s.s_store_sk = ca.ca_address_sk
LEFT JOIN catalog_sales cs ON s.s_store_sk = cs.cs_store_sk
LEFT JOIN (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS ws_total_sales_price 
    FROM web_sales 
    GROUP BY ws_item_sk
    HAVING SUM(ws_ext_sales_price) > 1000
) ws ON ws.ws_item_sk = cs.cs_item_sk
LEFT JOIN TopSales ts ON ts.ws_item_sk = cs.cs_item_sk
WHERE ca.ca_state IS NOT NULL AND ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT cs.cs_order_number) > 10 OR AVG(TOP_SALES.ws_ext_sales_price) IS NOT NULL
ORDER BY "Store Catalog Sales" DESC, "Total Catalog Profit" ASC
LIMIT 10;
