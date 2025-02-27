
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk = (SELECT MAX(ws_ship_date_sk) FROM web_sales)
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 10000 AND 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
highest_selling_item AS (
    SELECT ws_item_sk
    FROM ranked_sales
    WHERE rank_profit = 1
)

SELECT 
    ca.ca_address_id AS customer_address,
    wd.wd_name AS warehouse_name,
    cs.cs_sales_price,
    hd.hd_buy_potential,
    COALESCE(NULLIF(cd_cd_credit_rating, ''), 'UNKNOWN') AS credit_rating,
    CASE WHEN ic.total_on_hand IS NULL THEN 'OUT OF STOCK' ELSE CAST(ic.total_on_hand AS VARCHAR) END AS inventory_status
FROM 
    customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_data cd ON c.c_customer_id = cd.c_customer_id
    LEFT JOIN item i ON i.i_item_sk IN (SELECT ws_item_sk FROM highest_selling_item)
    LEFT JOIN store_sales cs ON cs.ss_item_sk = i.i_item_sk
    JOIN warehouse wd ON wd.w_warehouse_sk = (SELECT i_wholesale_cost FROM inventory WHERE inv_item_sk = i.i_item_sk LIMIT 1)
    LEFT JOIN inventory_check ic ON ic.inv_item_sk = i.i_item_sk
WHERE 
    cs.ss_sales_price > 
        (SELECT AVG(ss_sales_price) 
         FROM store_sales 
         WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales))
         AND ss_qs_sales_price < 200.00
        )
ORDER BY 
    customer_address,
    warehouse_name DESC
FETCH FIRST 50 ROWS ONLY;
