
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_email_address,
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date DESC) AS recent_purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE d.d_year >= 2022
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = YEAR(CURRENT_DATE) 
        AND d.d_month IN (1, 2, 3) 
        AND d.d_week_seq < (SELECT MAX(d2.d_week_seq) FROM date_dim d2 WHERE d2.d_year = YEAR(CURRENT_DATE))
    )
    GROUP BY ws.ws_item_sk
),
store_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_date_sk = (
        SELECT MAX(inv2.inv_date_sk) 
        FROM inventory inv2 
        WHERE inv2.inv_item_sk = inv.inv_item_sk
    )
    GROUP BY inv.inv_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_email_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ISNULL(si.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    ISNULL(is.total_quantity, 0) AS total_quantity_sold,
    ISNULL(is.order_count, 0) AS order_count,
    ISNULL(is.avg_sales_price, 0) AS avg_sales_price,
    ISNULL(is.total_profit, 0) AS total_profit,
    CASE 
        WHEN ISNULL(is.total_quantity, 0) = 0 THEN 'No Sales'
        ELSE CAST(ROUND((ISNULL(is.total_profit, 0) / NULLIF(is.total_quantity, 0)), 2) AS VARCHAR(10))
    END AS profit_per_item
FROM customer_info ci
LEFT JOIN item_sales is ON ci.c_customer_id = SUBSTRING(CAST(is.ws_item_sk AS CHAR), 1, 16)
LEFT JOIN store_inventory si ON is.ws_item_sk = si.inv_item_sk
WHERE ci.recent_purchase_rank = 1
ORDER BY ci.c_customer_id;
