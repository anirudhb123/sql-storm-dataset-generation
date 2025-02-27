
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
), 
PriceData AS (
    SELECT i.i_item_sk, 
           i.i_item_desc, 
           AVG(ws.ws_sales_price) AS avg_sales_price, 
           SUM(ws.ws_quantity) AS total_sold
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
), 
SalesStats AS (
    SELECT d.d_year, 
           SUM(ws.ws_net_profit) AS total_profit, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2021 AND 2022
    GROUP BY d.d_year
), 
TopItems AS (
    SELECT pd.i_item_sk, 
           pd.i_item_desc,
           pd.avg_sales_price,
           pd.total_sold,
           ROW_NUMBER() OVER (ORDER BY pd.total_sold DESC) AS rank
    FROM PriceData pd
)
SELECT ch.c_first_name, 
       ch.c_last_name, 
       st.total_profit, 
       ti.i_item_desc, 
       ti.avg_sales_price
FROM CustomerHierarchy ch
LEFT JOIN SalesStats st ON ch.c_current_cdemo_sk = st.total_orders
JOIN TopItems ti ON ti.rank <= 10
WHERE (ch.c_customer_sk IS NOT NULL OR ch.c_current_cdemo_sk IS NULL)
ORDER BY st.total_profit DESC, ti.avg_sales_price DESC;
