
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER(PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_net_profit) OVER(PARTITION BY ws.ws_item_sk) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk 
          BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighValueItems AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        rs.ws_sales_price,
        rs.total_quantity,
        rs.total_net_profit
    FROM RankedSales rs
    WHERE rs.price_rank = 1 
      AND rs.total_quantity > (SELECT AVG(total_qty) FROM (SELECT SUM(ws_quantity) AS total_qty FROM web_sales GROUP BY ws_item_sk) AS qty_table)
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_credit_rating, 
        ca.ca_state,
        CASE 
            WHEN (cd.cd_marital_status = 'M' AND cd.cd_gender = 'F') THEN 'Married Female'
            WHEN (cd.cd_marital_status = 'M' THEN 'Married Male'
            WHEN (cd.cd_marital_status = 'S') THEN 'Single'
            ELSE 'Other'
        END AS marital_status_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL
)
SELECT 
    ct.c_customer_id,
    ct.marital_status_category,
    COUNT(DISTINCT hi.ws_order_number) AS orders_count,
    SUM(hi.ws_sales_price) AS total_spent,
    SUM(hi.total_net_profit) AS total_profit
FROM CustomerDetails ct
JOIN HighValueItems hi ON hi.ws_item_sk IN (
    SELECT DISTINCT inv.inv_item_sk 
    FROM inventory inv 
    WHERE inv.inv_quantity_on_hand > 0 
      AND inv.inv_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
INNER JOIN web_sales ws ON hi.ws_item_sk = ws.ws_item_sk
GROUP BY ct.c_customer_id, ct.marital_status_category
HAVING total_spent > (SELECT AVG(total_spent) FROM (SELECT SUM(ws.sales_price) AS total_spent FROM web_sales ws GROUP BY ws.bill_customer_sk) AS avg_spent)
ORDER BY total_spent DESC
LIMIT 100;
