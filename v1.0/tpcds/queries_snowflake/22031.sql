
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451546
    GROUP BY ws_item_sk, ws_order_number
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(MAX(i.i_current_price), 0) AS max_price,
        COUNT(DISTINCT i.i_brand) AS unique_brands
    FROM item AS i
    LEFT JOIN catalog_sales AS cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    SUM(sd.total_net_profit) AS total_profit,
    ii.i_item_desc,
    ii.max_price,
    ii.unique_brands
FROM customer_info AS ci
LEFT JOIN sales_data AS sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN item_info AS ii ON sd.ws_item_sk = ii.i_item_sk
WHERE ci.gender_rank <= 10 
AND (ci.cd_purchase_estimate IS NOT NULL AND ci.cd_purchase_estimate > 1000) 
GROUP BY ci.c_first_name, ci.c_last_name, ii.i_item_desc, ii.max_price, ii.unique_brands
HAVING SUM(sd.total_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) % 10;
