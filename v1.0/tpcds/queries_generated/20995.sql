
WITH RECURSIVE sale_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(cd.cd_gender, 'U') AS gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_profit) > 0 
        OR cd.cd_marital_status IS NULL
),
inventory_analysis AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        CASE 
            WHEN SUM(i.inv_quantity_on_hand) BETWEEN 1 AND 50 THEN 'Low'
            WHEN SUM(i.inv_quantity_on_hand) BETWEEN 51 AND 150 THEN 'Medium'
            ELSE 'High' 
        END AS inventory_band
    FROM 
        inventory i
    WHERE 
        i.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        i.i_item_sk
),
promotion_analysis AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_with_promo,
        SUM(ws.ws_net_profit) AS net_profit_generated
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
    HAVING 
        SUM(ws.ws_net_profit) > 0
)
SELECT 
    ss.ss_store_sk,
    ss.total_sales,
    cs.c_first_name,
    cs.c_last_name,
    cs.gender,
    cs.marital_status,
    ia.total_inventory,
    ia.inventory_band,
    pa.orders_with_promo,
    pa.net_profit_generated
FROM 
    sale_summary ss
LEFT JOIN 
    customer_stats cs ON cs.total_net_profit > (
        SELECT AVG(total_net_profit) FROM customer_stats
    )
LEFT JOIN 
    inventory_analysis ia ON ia.i_item_sk IN (
        SELECT ws.ws_item_sk 
        FROM web_sales ws 
        WHERE ws.ws_net_profit > 0 
        GROUP BY ws.ws_item_sk 
        HAVING COUNT(ws.ws_order_number) > 5
    )
LEFT JOIN 
    promotion_analysis pa ON pa.orders_with_promo > 10
WHERE 
    ss.rank <= 10
ORDER BY 
    ss.total_sales DESC, cs.total_net_profit DESC;
