
WITH RecursiveSales AS (
    SELECT ws_item_sk, SUM(ws_net_profit) AS total_profit, COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_bill_customer_sk IN (
        SELECT c_customer_sk
        FROM customer
        WHERE c_birth_year BETWEEN 1980 AND 1990
        AND c_preferred_cust_flag = 'Y'
    )
    GROUP BY ws_item_sk

    UNION ALL

    SELECT cs_item_sk, SUM(cs_net_profit) AS total_profit, COUNT(DISTINCT cs_order_number) AS order_count
    FROM catalog_sales
    WHERE cs_ship_mode_sk IN (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_type LIKE '%Express%'
    )
    GROUP BY cs_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(ws.total_profit, 0) AS web_sales_profit,
    COALESCE(cs.total_profit, 0) AS catalog_sales_profit,
    (COALESCE(ws.total_profit, 0) + COALESCE(cs.total_profit, 0)) AS combined_profit,
    (SELECT COUNT(DISTINCT c.c_customer_id)
     FROM customer c
     INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
     WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'S'
    ) AS single_female_customers
FROM item i
LEFT JOIN (SELECT ws_item_sk, total_profit FROM RecursiveSales WHERE total_profit IS NOT NULL) ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN (SELECT cs_item_sk, total_profit FROM RecursiveSales WHERE total_profit IS NOT NULL) cs ON i.i_item_sk = cs.cs_item_sk
WHERE (COALESCE(ws.total_profit, 0) > 500 OR COALESCE(cs.total_profit, 0) > 500)
AND i.i_color IS NOT NULL
ORDER BY combined_profit DESC, i.i_item_id
LIMIT 10
OFFSET (SELECT COUNT(DISTINCT item.i_item_sk) FROM item) / 2;
