
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_cdemo_sk, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           ch.c_current_cdemo_sk, level + 1
    FROM customer c 
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk 
    WHERE level < 5
),
SalesData AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_net_profit) AS total_net_profit, 
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
AddressCounts AS (
    SELECT ca.ca_address_sk, 
           COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk
),
DiscountedSales AS (
    SELECT cs.cs_order_number, cs.cs_sales_price - cs.cs_ext_discount_amt AS net_price
    FROM catalog_sales cs
    WHERE cs.cs_list_price > 20 AND (cs.cs_ext_discount_amt IS NOT NULL OR cs.cs_ext_discount_amt = 0)
),
RankedOrders AS (
    SELECT ws.ws_order_number, 
           RANK() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws 
    WHERE ws.ws_sales_price < 500
)
SELECT ch.c_first_name, ch.c_last_name, 
       COALESCE(da.customer_count, 0) AS customer_count, 
       sd.total_net_profit, 
       COALESCE(dr.price_rank, 'No Rank') AS order_rank
FROM CustomerHierarchy ch
LEFT JOIN AddressCounts da ON ch.c_current_cdemo_sk = da.ca_address_sk
LEFT JOIN SalesData sd ON ch.c_current_cdemo_sk = sd.ws_item_sk
LEFT JOIN RankedOrders dr ON ch.c_current_hdemo_sk = dr.ws_order_number
WHERE ch.level <= 3
AND (sd.total_net_profit IS NOT NULL OR dr.price_rank IS NOT NULL)
ORDER BY customer_count DESC, total_net_profit DESC;
