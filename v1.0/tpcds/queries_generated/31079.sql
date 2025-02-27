
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_agg AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws_net_paid) AS total_spent,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
in_stock AS (
    SELECT 
        i.i_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY i.i_item_sk
)

SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_paid) AS avg_net_paid,
    (SELECT COUNT(DISTINCT wr.returning_customer_sk) 
     FROM web_returns wr 
     WHERE wr.wr_item_sk = ws.ws_item_sk) AS return_count
FROM web_sales ws
LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN sales_cte s ON ws.ws_item_sk = s.ws_item_sk
JOIN customer_agg ca_agg ON ws.ws_bill_customer_sk = ca_agg.c_customer_sk
JOIN in_stock is ON ws.ws_item_sk = is.i_item_sk
WHERE ws.ws_ship_date_sk IS NOT NULL
  AND ws.ws_quantity > 0
  AND ca.ca_state IS NOT NULL
  AND s.rn = 1
GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
HAVING total_sales > (SELECT AVG(total_spent) FROM customer_agg)
ORDER BY total_sales DESC
LIMIT 100;
