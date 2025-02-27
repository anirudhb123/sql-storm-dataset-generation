
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_orders
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
),
customer_ranks AS (
    SELECT 
        c.c_customer_id,
        cd_demo_sk,
        DENSE_RANK() OVER (PARTITION BY c.c_country ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL
),
date_range AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year >= 2022 AND dd.d_year <= 2023
    GROUP BY d_year, d_month_seq
),
item_inventory AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        MAX(inv_quantity_on_hand) AS max_inventory
    FROM inventory
    GROUP BY inv_date_sk, inv_item_sk
)
SELECT 
    cs.c_customer_id,
    cs.rank,
    dr.orders_count,
    dr.total_profit,
    ii.max_inventory,
    ss.total_sales
FROM customer_ranks cs
JOIN date_range dr ON cs.cd_demo_sk = dr.d_year
JOIN item_inventory ii ON cs.c_customer_id = ii.inv_item_sk
JOIN sales_summary ss ON ii.inv_item_sk = ss.ws_item_sk
WHERE cs.rank <= 10
ORDER BY dr.orders_count DESC, ss.total_sales DESC
LIMIT 50;
