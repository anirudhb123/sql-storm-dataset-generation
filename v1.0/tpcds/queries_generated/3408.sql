
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451917 AND 2451923
),
item_summary AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(sd.ws_quantity), 0) AS total_quantity_sold,
        COALESCE(SUM(sd.ws_net_profit), 0) AS total_net_profit
    FROM item i
    LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
),
top_selling_items AS (
    SELECT 
        is.item_sk,
        is.item_desc,
        is.current_price,
        is.total_quantity_sold,
        is.total_net_profit,
        DENSE_RANK() OVER (ORDER BY is.total_net_profit DESC) AS profit_rank
    FROM (
        SELECT 
            i.i_item_sk AS item_sk,
            i.i_item_desc AS item_desc,
            i.i_current_price AS current_price,
            COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
            COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
        FROM item i
        LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
        GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
    ) is
)
SELECT 
    ti.i_item_sk,
    ti.i_item_desc,
    ti.i_current_price,
    ti.total_quantity_sold,
    ti.total_net_profit,
    CC.cc_country,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM top_selling_items ti
LEFT JOIN customer c ON c.c_current_cdemo_sk IN (
    SELECT cd_demo_sk 
    FROM customer_demographics 
    WHERE cd_credit_rating = 'Good' 
    AND cd_marital_status = 'M'
)
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk IN (
    SELECT DISTINCT ws.ws_warehouse_sk 
    FROM web_sales ws 
    WHERE ws.ws_item_sk = ti.i_item_sk
)
LEFT JOIN call_center CC ON CC.cc_call_center_sk =(
    SELECT cc_call_center_sk 
    FROM call_center  cc 
    WHERE cc.cc_name = 'Los Angeles'
)
WHERE ti.profit_rank <= 10
GROUP BY ti.i_item_sk, ti.i_item_desc, ti.i_current_price, ti.total_quantity_sold, ti.total_net_profit, CC.cc_country
ORDER BY ti.total_net_profit DESC;
