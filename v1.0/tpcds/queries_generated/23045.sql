
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS rank_quantity,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'Unknown Price'
            ELSE CAST(ws.ws_sales_price AS varchar)
        END AS sales_price_label
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        COALESCE(cd.cd_gender, 'NOT SPECIFIED') AS gender,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_email_address, cd.cd_gender
),
inventory_check AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) < 10 THEN 'LOW STOCK'
            WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 10 AND 50 THEN 'MEDIUM STOCK'
            ELSE 'HIGH STOCK'
        END AS stock_level
    FROM inventory inv 
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    cs.c_email_address,
    cs.gender,
    COALESCE(cs.total_profit, 0) AS total_profit,
    is.total_inventory,
    is.stock_level,
    rs.ws_order_number,
    rs.ws_quantity,
    rs.ws_sales_price,
    rs.rank_price,
    rs.rank_quantity,
    rs.sales_price_label
FROM customer_summary cs
LEFT JOIN inventory_check is ON cs.c_customer_sk = is.i_item_sk
LEFT JOIN ranked_sales rs ON cs.c_email_address = rs.sales_price_label
WHERE cs.total_profit > 0
    AND (rs.rank_price IS NOT NULL OR rs.rank_quantity IS NOT NULL)
ORDER BY total_profit DESC, stock_level, cs.c_email_address
FETCH FIRST 100 ROWS ONLY;
