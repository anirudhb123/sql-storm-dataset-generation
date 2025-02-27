
WITH RECURSIVE CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name,
           c.c_last_name,
           ws.ws_sold_date_sk,
           ws.ws_quantity,
           ws.ws_sales_price,
           ws.ws_net_paid
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    UNION ALL
    SELECT c.c_customer_sk, 
           c.c_first_name,
           c.c_last_name,
           ws.ws_sold_date_sk,
           ws.ws_quantity,
           ws.ws_sales_price,
           ws.ws_net_paid
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim) 
          AND (ws.ws_sold_date_sk, ws.ws_net_paid) IN (SELECT ws.ws_sold_date_sk, MAX(ws.ws_net_paid) 
                                                        FROM web_sales ws 
                                                        GROUP BY ws.ws_sold_date_sk)
),
ItemSales AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_net_paid) AS total_sales
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
AggregatedSales AS (
    SELECT cs.c_customer_sk, 
           cs.c_first_name, 
           cs.c_last_name,
           SUM(isales.total_quantity_sold) AS total_quantity,
           SUM(isales.total_sales) AS total_spent
    FROM CustomerSales cs
    JOIN ItemSales isales ON cs.ws_sold_date_sk = isales.i_item_sk
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name
)
SELECT a.c_customer_sk,
       a.c_first_name,
       a.c_last_name,
       COALESCE(a.total_quantity, 0) AS total_quantity,
       COALESCE(a.total_spent, 0.00) AS total_spent,
       CASE 
           WHEN a.total_spent > 1000 THEN 'High Roller'
           WHEN a.total_spent > 500 THEN 'Moderate Buyer'
           ELSE 'Occasional Shopper'
       END AS customer_type
FROM AggregatedSales a
LEFT JOIN customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = a.c_customer_sk)
WHERE ca.ca_state = 'CA'
ORDER BY a.total_spent DESC
LIMIT 100;
