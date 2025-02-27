
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        1 AS hierarchy_level
    FROM 
        store
    WHERE 
        s_state = 'CA'
    
    UNION ALL
    
    SELECT 
        s_store_sk,
        s_store_name,
        sh.hierarchy_level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE 
        sh.hierarchy_level < 10
),
sales_summary AS (
    SELECT 
        cs.s_sales_price,
        cs.cs_quantity,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_list_price) AS average_list_price,
        ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales cs
    JOIN 
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2451545 AND 2451545 + 364
    GROUP BY 
        cs.s_sales_price, cs.cs_quantity, sm.sm_type
),
customer_ranks AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    sh.s_store_name,
    sr.sr_return_quantity,
    COALESCE(cs.total_profit, 0) AS total_profit,
    cr.c_first_name,
    cr.c_last_name,
    cr.purchase_rank,
    CASE 
        WHEN cr.purchase_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_state IS NULL) AS null_address_count
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_returns sr ON sh.s_store_sk = sr.s_store_sk
LEFT JOIN 
    sales_summary cs ON sr.sr_item_sk = cs.cs_item_sk
LEFT JOIN 
    customer_ranks cr ON sr.sr_customer_sk = cr.c_customer_id
WHERE 
    sr.sr_return_quantity > 0
    AND sh.hierarchy_level <= 5
ORDER BY 
    total_profit DESC, sh.s_store_name;
