
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
top_sellers AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_net_profit DESC) AS seller_rank
    FROM
        store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL AND 
        ca.ca_state IN ('NY', 'CA') 
        AND ss.ss_net_profit > 0
),
calendar AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_quarter_seq,
        d.d_date
    FROM 
        date_dim d
    WHERE 
        d.d_year BETWEEN 2020 AND 2023 AND
        d.d_week_seq IS NOT NULL
),
inventory_levels AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock,
        COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count
    FROM 
        inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(ts.ss_item_sk, 0) AS item_sk,
    COALESCE(ts.ss_quantity, 0) AS quantity,
    COALESCE(ts.ss_net_profit, 0) AS net_profit,
    COALESCE(ss.total_quantity, 0) AS total_web_quantity,
    COALESCE(ss.total_profit, 0) AS total_web_profit,
    ca.ca_city,
    ca.ca_state,
    il.total_stock,
    il.warehouse_count,
    'The profit is: ' || CAST(COALESCE(ts.ss_net_profit, 0) AS VARCHAR) AS profit_statement
FROM 
    customer c
LEFT JOIN 
    top_sellers ts ON c.c_customer_sk = ts.ss_customer_sk AND ts.seller_rank <= 5
LEFT JOIN 
    sales_summary ss ON ts.ss_item_sk = ss.ws_item_sk
LEFT JOIN 
    inventory_levels il ON ts.ss_item_sk = il.inv_item_sk
JOIN 
    calendar cal ON cal.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                  AND cal.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    c.c_customer_id, ts.ss_item_sk;
