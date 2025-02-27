
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
total_sales AS (
    SELECT 
        item.i_item_id,
        item.i_current_price,
        COALESCE(SUM(ws.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.total_net_profit), 0) AS total_net_profit
    FROM item 
    LEFT JOIN sales_data ws ON item.i_item_sk = ws.ws_item_sk
    WHERE item.i_rec_end_date IS NULL
    GROUP BY item.i_item_id, item.i_current_price
),
high_performing_items AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM total_sales
    WHERE total_net_profit > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        MAX(CASE WHEN h.hd_income_band_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_income_data
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT
    ct.c_customer_id,
    ct.cd_gender,
    ct.cd_marital_status,
    ct.cd_purchase_estimate,
    hpi.i_item_id,
    hpi.i_current_price,
    hpi.total_quantity,
    hpi.total_net_profit,
    CASE 
        WHEN ct.has_income_data = 1 THEN 'Has Data'
        ELSE 'No Data' 
    END AS income_band_data
FROM high_performing_items hpi
JOIN customer_info ct ON hpi.total_quantity > (SELECT AVG(total_quantity) FROM high_performing_items)
LEFT JOIN promotion p ON hpi.i_item_id = p.p_item_sk
WHERE p.p_discount_active = 'Y' OR p.p_purpose LIKE '%season%'
ORDER BY hpi.rank, ct.c_customer_id
LIMIT 100;
