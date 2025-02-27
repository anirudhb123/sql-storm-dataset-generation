WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 3
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
    GROUP BY ws.ws_item_sk
),
FilteredSales AS (
    SELECT sd.ws_item_sk, sd.total_quantity, sd.total_sales
    FROM SalesData sd
    WHERE sd.rank <= 10
)
SELECT 
    ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
    COALESCE(SUM(fs.total_sales), 0) AS total_spent,
    COUNT(DISTINCT fs.ws_item_sk) AS unique_items_purchased,
    MAX(fs.total_quantity) AS max_quantity_purchased
FROM CustomerHierarchy ch
LEFT JOIN FilteredSales fs ON ch.c_current_cdemo_sk = fs.ws_item_sk
GROUP BY ch.c_first_name, ch.c_last_name
HAVING SUM(COALESCE(fs.total_sales, 0)) > (SELECT AVG(total_spent) FROM (
    SELECT SUM(total_sales) AS total_spent 
    FROM FilteredSales 
    GROUP BY ws_item_sk
) avg_sales)
ORDER BY total_spent DESC
LIMIT 5;