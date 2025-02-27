
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_preferred_cust_flag, ch.c_current_cdemo_sk, ch.level + 1
    FROM customer ch
    JOIN CustomerHierarchy ch_parent ON ch.c_current_cdemo_sk = ch_parent.c_current_cdemo_sk
    WHERE ch.level < 5
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_profit, 
        sd.order_count,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS rank
    FROM SalesData sd
    WHERE sd.order_count > 0
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_preferred_cust_flag,
    fs.ws_item_sk,
    fs.total_profit,
    fs.order_count,
    w.w_warehouse_name,
    w.w_city,
    w.w_state
FROM CustomerHierarchy ch
LEFT JOIN FilteredSales fs ON fs.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand IN ('BrandA', 'BrandB'))
LEFT JOIN warehouse w ON w.w_warehouse_sk = (
    SELECT inv.inv_warehouse_sk
    FROM inventory inv
    WHERE inv.inv_item_sk = fs.ws_item_sk
    AND inv.inv_quantity_on_hand > 0
    LIMIT 1
)
WHERE ch.level = 1
AND fs.rank <= 10
ORDER BY fs.total_profit DESC, ch.c_last_name ASC;
