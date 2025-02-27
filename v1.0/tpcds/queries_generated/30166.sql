
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.quantity) AS total_quantity,
        SUM(ss.net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.net_profit) DESC) AS rank
    FROM store_sales ss
    WHERE ss.sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ss.sold_date_sk, ss.item_sk
),
top_items AS (
    SELECT 
        item_sk, 
        total_quantity,
        total_profit
    FROM sales_data
    WHERE rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ADDRESS.ca_city, 
        ADDRESS.ca_state,
        coalesce(ADDRESS.ca_country, 'Unknown') as country
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ADDRESS ON c.c_current_addr_sk = ADDRESS.ca_address_sk
),
inventory_snapshot AS (
    SELECT 
        i.item_sk,
        i.i_item_desc,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_available
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk 
    WHERE inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        ci.country,
        ti.total_quantity,
        ti.total_profit,
        isnap.i_item_desc,
        isnap.quantity_available
    FROM top_items ti
    JOIN customer_info ci ON ti.item_sk = (SELECT TOP 1 ws_item_sk FROM web_sales WHERE ws_item_sk = ti.item_sk)
    JOIN inventory_snapshot isnap ON ti.item_sk = isnap.item_sk
)
SELECT 
    * 
FROM final_report
WHERE total_profit > 5000 
OR quantity_available < 20
ORDER BY total_profit DESC, quantity_available ASC;
