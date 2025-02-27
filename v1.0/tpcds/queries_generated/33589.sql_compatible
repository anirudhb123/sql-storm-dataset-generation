
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_store_sk, ss_item_sk

    UNION ALL 

    SELECT 
        sh.ss_store_sk,
        sh.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit,
        sh.level + 1
    FROM 
        store_sales ss
    INNER JOIN 
        sales_hierarchy sh ON ss.ss_store_sk = sh.ss_store_sk AND ss.ss_item_sk = sh.ss_item_sk
    WHERE 
        ss.sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        sh.ss_store_sk, sh.ss_item_sk, sh.level
),

address_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_income_band_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'S') AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),

profit_analysis AS (
    SELECT 
        si.ss_store_sk,
        SUM(si.total_profit) AS store_profit,
        COUNT(DISTINCT si.ss_item_sk) AS distinct_items_sold 
    FROM 
        sales_hierarchy si
    GROUP BY 
        si.ss_store_sk
)

SELECT 
    a.ca_city,
    a.ca_state,
    p.store_profit,
    p.distinct_items_sold,
    COALESCE(d.d_gender, 'Unknown') AS gender,
    CASE 
        WHEN p.store_profit > 1000 THEN 'High Performer' 
        WHEN p.store_profit > 500 THEN 'Medium Performer' 
        ELSE 'Low Performer' 
    END AS performance_band
FROM 
    address_info a
JOIN 
    profit_analysis p ON a.c_customer_sk = p.ss_store_sk 
LEFT JOIN 
    (SELECT DISTINCT cd_demo_sk AS d_demo_sk, cd_gender AS d_gender FROM customer_demographics) d ON a.cd_income_band_sk = d.d_demo_sk
WHERE 
    p.store_profit IS NOT NULL
ORDER BY 
    p.store_profit DESC, a.ca_city;
