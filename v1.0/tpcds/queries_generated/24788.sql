
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
item_info AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(d.cd_gender, 'Unknown') AS gender,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price < 20 THEN 'Low Price'
            WHEN i.i_current_price BETWEEN 20 AND 100 THEN 'Moderate Price'
            ELSE 'High Price'
        END AS price_category
    FROM item i
    LEFT JOIN customer_demographics d ON d.cd_demo_sk = (
        SELECT TOP 1 cd_demo_sk 
        FROM customer 
        WHERE c_customer_sk = (
            SELECT TOP 1 ws_bill_customer_sk 
            FROM web_sales 
            WHERE ws_item_sk = i.i_item_sk 
            ORDER BY ws_sold_date_sk DESC
        )
    )
),
final_data AS (
    SELECT
        ii.i_item_sk,
        ii.i_item_id,
        ii.gender,
        ii.price_category,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        DENSE_RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank,
        CASE 
            WHEN ii.gender = 'Unknown' THEN 'Gender Data Missing'
            ELSE ii.gender
        END AS adjusted_gender
    FROM item_info ii
    LEFT JOIN sales_data sd ON ii.i_item_sk = sd.ws_item_sk
)
SELECT 
    COALESCE(price_category, 'Not Classified') AS category,
    adjusted_gender,
    SUM(total_quantity) AS total_quantity,
    SUM(total_sales) AS total_sales,
    MAX(total_profit) AS max_profit,
    COUNT(*) AS item_count
FROM final_data
GROUP BY
    price_category,
    adjusted_gender
HAVING
    SUM(total_sales) > (SELECT AVG(total_sales) FROM final_data)
ORDER BY 
    MAX(total_profit) DESC
LIMIT 10
OFFSET 5;
