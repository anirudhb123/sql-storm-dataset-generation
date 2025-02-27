
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COALESCE(hd.hd_income_band_sk, 0) as income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year >= 1980
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' Jr.' as c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COALESCE(hd.hd_income_band_sk, 0) as income_band
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year < 1980
    AND 
        cd.cd_marital_status = 'M'
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) as total_orders,
        SUM(ws_net_profit) as total_profit,
        AVG(ws_net_paid_inc_tax) as avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) as total_quantity
    FROM 
        inventory inv
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.income_band,
    ss.total_orders,
    ss.total_profit,
    ss.avg_order_value,
    CASE 
        WHEN ss.total_profit > 1000 THEN 'High Profit'
        WHEN ss.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END as profit_category,
    COUNT(DISTINCT inv.inv_item_sk) as unique_items_in_inventory,
    ROW_NUMBER() OVER (PARTITION BY ch.income_band ORDER BY ss.total_profit DESC) as profit_rank
FROM 
    customer_hierarchy ch
LEFT JOIN 
    sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    inventory_status inv ON inv.inv_item_sk = ch.c_customer_sk
GROUP BY 
    ch.c_customer_sk, 
    ch.c_first_name, 
    ch.c_last_name, 
    ch.cd_gender, 
    ch.income_band, 
    ss.total_orders, 
    ss.total_profit, 
    ss.avg_order_value
ORDER BY 
    profit_rank;
