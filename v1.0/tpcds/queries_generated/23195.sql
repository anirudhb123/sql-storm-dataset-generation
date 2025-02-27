
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year,
           '' AS hierarchy, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year,
           CONCAT(ch.hierarchy, ' > ', c.c_first_name, ' ', c.c_last_name),
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 3  -- Limit level to avoid infinite recursion
),
ItemSales AS (
    SELECT i.i_item_sk, i.i_item_desc, SUM(ws.ws_quantity) AS total_quantity, 
           AVG(ws.ws_sales_price) AS avg_price, 
           ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY i.i_item_sk, i.i_item_desc
),
ComplexCalculation AS (
    SELECT ich.c_customer_sk, ich.c_first_name, ich.c_last_name, ich.hierarchy,
           isales.i_item_sk, isales.i_item_desc,
           CASE 
               WHEN isales.total_quantity IS NULL THEN 0
               ELSE isales.total_quantity * isales.avg_price 
           END AS total_sales
    FROM CustomerHierarchy ich
    LEFT JOIN ItemSales isales ON ich.c_customer_sk = isales.i_item_sk
)
SELECT ch.c_first_name, ch.c_last_name, ch.hierarchy,
       COALESCE(SUM(cc.total_sales), 0) AS grand_total_sales,
       COUNT(DISTINCT isales.i_item_sk) AS distinct_items_sold,
       AVG(CASE WHEN cc.total_sales > 0 THEN cc.total_sales ELSE NULL END) AS avg_sales_per_item,
       STRING_AGG(DISTINCT isales.i_item_desc, ', ') WITHIN GROUP (ORDER BY isales.i_item_desc) AS item_descriptions
FROM ComplexCalculation cc
JOIN CustomerHierarchy ch ON cc.c_customer_sk = ch.c_customer_sk
LEFT JOIN ItemSales isales ON cc.i_item_sk = isales.i_item_sk
GROUP BY ch.c_first_name, ch.c_last_name, ch.hierarchy
HAVING grand_total_sales > 0
ORDER BY grand_total_sales DESC
LIMIT 10;
