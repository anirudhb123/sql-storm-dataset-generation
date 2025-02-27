
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        1 AS level 
    FROM 
        store_sales 
    GROUP BY 
        ss_store_sk 
    UNION ALL 
    SELECT 
        sh.ss_store_sk,
        sh.total_sales * 1.10 AS total_sales, 
        sh.level + 1 
    FROM 
        sales_hierarchy sh 
    JOIN 
        store s ON sh.ss_store_sk = s.s_store_sk 
    WHERE 
        sh.level < 5
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent 
    FROM 
        customer c 
    LEFT JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count 
    FROM 
        customer_address ca 
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk 
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
final_report AS (
    SELECT 
        ch.c_customer_sk, 
        ch.gender, 
        ch.total_orders, 
        ch.total_spent,
        ai.customer_count,
        sh.total_sales
    FROM 
        customer_stats ch 
    INNER JOIN 
        address_info ai ON ch.c_customer_sk = ai.customer_count
    LEFT JOIN 
        sales_hierarchy sh ON sh.ss_store_sk = (SELECT s_store_sk FROM store ORDER BY RANDOM() LIMIT 1)
)
SELECT 
    *,
    CASE 
        WHEN total_spent IS NULL THEN 'No Sales'
        ELSE 'Active Buyer'
    END AS customer_status,
    ROW_NUMBER() OVER (PARTITION BY gender ORDER BY total_spent DESC) AS rank_within_gender
FROM 
    final_report
WHERE 
    customer_count > 1
ORDER BY 
    total_spent DESC;
