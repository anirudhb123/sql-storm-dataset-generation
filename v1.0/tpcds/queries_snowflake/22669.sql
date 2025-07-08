
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_marital_status = 'M')
),
promotional_analysis AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2000) 
    GROUP BY 
        p.p_promo_id
),
inventory_check AS (
    SELECT 
        i.i_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand < 5 THEN 1 ELSE 0 END) AS low_stock_count
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) > 0
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.ca_city,
    pa.p_promo_id,
    pa.order_count,
    pa.total_profit,
    i.low_stock_count,
    CASE WHEN i.low_stock_count > 0 THEN 'Stock Alert' ELSE 'Stock Sufficient' END AS stock_status
FROM 
    customer_hierarchy ch
LEFT JOIN 
    promotional_analysis pa ON TRUE 
LEFT JOIN 
    inventory_check i ON i.i_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ch.c_customer_sk)
WHERE 
    ch.rn <= 10 
    AND NOT EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_customer_sk = ch.c_customer_sk AND ss.ss_sold_date_sk = 20230101) 
ORDER BY 
    ch.ca_city, ch.c_birth_year DESC;
