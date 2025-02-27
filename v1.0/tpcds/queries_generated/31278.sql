
WITH RECURSIVE category_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        0 AS level,
        i.i_category AS category
    FROM 
        item i
    WHERE 
        i.i_category IS NOT NULL
    UNION ALL
    SELECT 
        c.i_item_sk,
        c.i_item_id,
        ch.level + 1,
        c.i_category
    FROM 
        item c
    JOIN 
        category_hierarchy ch ON c.i_category_id = ch.i_item_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        ws.ws_item_sk
),
customer_analysis AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(IF(cd.cd_gender = 'M', 1, 0)) AS male_count,
        SUM(IF(cd.cd_gender = 'F', 1, 0)) AS female_count,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ca.category,
    cs.total_quantity_sold,
    cs.total_net_profit,
    ca.male_count,
    ca.female_count,
    ca.total_customers,
    COALESCE(cs.total_net_profit / NULLIF(cs.total_quantity_sold, 0), 0) AS avg_profit_per_item
FROM 
    category_hierarchy ca
LEFT JOIN 
    sales_summary cs ON ca.i_item_sk = cs.ws_item_sk
LEFT JOIN 
    customer_analysis ca ON 1=1
WHERE 
    cs.profit_rank <= 10
ORDER BY 
    ca.category, cs.total_net_profit DESC;
