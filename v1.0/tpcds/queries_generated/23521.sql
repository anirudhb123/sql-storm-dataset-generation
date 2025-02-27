
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 5
), address_and_demo AS (
    SELECT c.c_customer_id, ca.ca_country, cd.cd_gender, COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE ca.ca_country IS NOT NULL AND cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_id, ca.ca_country, cd.cd_gender
), sales_summary AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 7 FROM date_dim)
    GROUP BY ws.ws_bill_customer_sk
)
SELECT ad.c_customer_id, ad.ca_country, ad.cd_gender, 
    COALESCE(ss.total_profit, 0) AS total_profit_last_week,
    ih.i_item_id, ih.i_item_desc, 
    ROW_NUMBER() OVER (PARTITION BY ad.c_customer_id ORDER BY ad.return_count DESC) AS rank
FROM address_and_demo ad
FULL OUTER JOIN sales_summary ss ON ad.c_customer_id = ss.ws_bill_customer_sk
LEFT JOIN item_hierarchy ih ON ih.i_item_id = 'special_item' 
WHERE (ad.cd_gender = 'F' AND ad.ca_country <> 'USA')
  OR (ad.cd_gender = 'M' AND ad.ca_country IS NULL)
  AND (rank = 1 OR rank IS NULL)
ORDER BY total_profit_last_week DESC, ad.c_customer_id;
