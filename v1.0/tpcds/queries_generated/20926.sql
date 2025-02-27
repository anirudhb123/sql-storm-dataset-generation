
WITH SalesData AS (
    SELECT 
        coalesce(ss.ss_sold_date_sk, cs.cs_sold_date_sk, ws.ws_sold_date_sk) AS sold_date,
        cs.cs_item_sk AS item_sk, 
        COALESCE(ss.ss_quantity, cs.cs_quantity, ws.ws_quantity) AS quantity,
        CASE 
            WHEN ss.ss_item_sk IS NOT NULL THEN 'store' 
            WHEN cs.cs_item_sk IS NOT NULL THEN 'catalog' 
            ELSE 'web' 
        END AS sale_type,
        COALESCE(ss.ss_net_profit, cs.cs_net_profit, ws.ws_net_profit) AS net_profit
    FROM store_sales ss
    FULL OUTER JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
    FULL OUTER JOIN web_sales ws ON cs.cs_item_sk = ws.ws_item_sk
    WHERE COALESCE(ss.ss_sales_price, cs.cs_sales_price, ws.ws_sales_price) > 0
),
TopItems AS (
    SELECT 
        item_sk,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY sale_type ORDER BY total_profit DESC) AS rnk
    FROM SalesData
    GROUP BY item_sk, sale_type
    HAVING SUM(quantity) IS NOT NULL
)
SELECT 
    item_sk,
    total_quantity,
    total_profit,
    sale_type,
    CASE 
        WHEN rnk = 1 THEN 'Top Selling'
        ELSE 'Other' 
    END AS ranking
FROM TopItems
WHERE total_profit IS NOT NULL
UNION ALL 
SELECT 
    item_sk,
    (SELECT SUM(quantity) FROM SalesData WHERE sale_type = 'web') AS web_qty,
    NULL AS total_profit,
    'web' AS sale_type,
    'Web Total' AS ranking
FROM SalesData
GROUP BY item_sk
HAVING SUM(quantity) IS NULL
ORDER BY 1, 2 DESC;
