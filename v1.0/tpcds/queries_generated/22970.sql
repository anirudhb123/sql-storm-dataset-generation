
WITH RECURSIVE role_hierarchy AS (
    SELECT cc.cc_call_center_sk, cc.cc_name, cc.cc_manager, 0 AS level
    FROM call_center cc
    WHERE cc.cc_manager IS NOT NULL
    
    UNION ALL
    
    SELECT cc.cc_call_center_sk, cc.cc_name, cc.cc_manager, rh.level + 1
    FROM call_center cc
    INNER JOIN role_hierarchy rh ON cc.cc_manager = rh.cc_name
),
item_summary AS (
    SELECT i.i_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity_sold,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name,
           cd.cd_gender,
           CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married'
               ELSE 'Single'
           END AS marital_status,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank_year_of_birth
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT ci.c_customer_sk, 
       ci.c_first_name,
       ci.c_last_name,
       ci.marital_status,
       ISNULL(SUM(ws.ws_net_profit), 0) AS total_net_profit,
       CASE 
           WHEN SUM(ws.ws_quantity) IS NULL THEN 'No Sales'
           ELSE 'Has Sales'
       END AS sales_status,
       COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
       ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank,
       (SELECT COUNT(DISTINCT sr_ticket_number) 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = ci.c_customer_sk
        AND sr_return_quantity > 0) AS total_returns
FROM customer_info ci
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON ci.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN item_summary isum ON ws.ws_item_sk = isum.i_item_sk
LEFT JOIN role_hierarchy rh ON ci.c_last_name = rh.cc_manager
WHERE ci.rank_year_of_birth <= 10
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.marital_status
HAVING SUM(ws.ws_net_profit) > 1000 OR COUNT(DISTINCT cs.cs_order_number) > 5
ORDER BY total_net_profit DESC NULLS LAST;
