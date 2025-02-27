
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
sales_analysis AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(ranked_sales.total_quantity, 0) AS total_quantity_sold,
        COALESCE(ranked_sales.total_profit, 0) AS total_profit_generated
    FROM item
    LEFT JOIN ranked_sales ON item.i_item_sk = ranked_sales.ws_item_sk
),
location_analysis AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT sales_analysis.i_item_id) AS distinct_items_purchased
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN sales_analysis ON c.c_customer_sk = sales_analysis.i_item_sk
    GROUP BY c.c_customer_id, ca.ca_city, ca.ca_state
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(hd.hd_income_band_sk) AS avg_income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    la.ca_city,
    la.ca_state,
    la.distinct_items_purchased,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.avg_income_band,
    CASE 
        WHEN la.distinct_items_purchased > 50 THEN 'High Activity'
        WHEN la.distinct_items_purchased BETWEEN 20 AND 50 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level
FROM location_analysis la
FULL OUTER JOIN customer_demographics cd ON la.c_customer_id = cd.cd_gender -- Intentional join on non-key column for corner case
WHERE cd.avg_income_band IS NOT NULL OR la.distinct_items_purchased IS NOT NULL
ORDER BY la.ca_city ASC NULLS LAST, la.ca_state ASC NULLS LAST, activity_level;
