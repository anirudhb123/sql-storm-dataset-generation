
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss.s_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        1 AS level
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_store_sk, ss.ss_item_sk

    UNION ALL

    SELECT 
        ss.s_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) + sh.total_quantity,
        SUM(ss.ss_net_paid) + sh.total_net_paid,
        sh.level + 1
    FROM 
        store_sales ss
    JOIN 
        sales_hierarchy sh ON ss.s_store_sk = sh.s_store_sk AND ss.ss_item_sk = sh.ss_item_sk
    GROUP BY 
        ss.s_store_sk, ss.ss_item_sk
    HAVING 
        sh.level < 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.s_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_state,
    ci.cd_gender,
    si.total_sales,
    si.total_transactions,
    sh.total_quantity,
    sh.total_net_paid,
    CASE 
        WHEN sh.total_net_paid IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary si ON ci.c_customer_sk = si.s_store_sk
LEFT JOIN 
    sales_hierarchy sh ON si.s_store_sk = sh.s_store_sk
WHERE 
    (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
    AND ci.rank_by_purchases < 10
    AND (ci.ca_state IS NOT NULL OR sh.total_quantity > 0)
ORDER BY 
    total_sales DESC, ci.c_last_name, ci.c_first_name;
