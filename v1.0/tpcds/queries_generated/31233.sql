
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_market_id,
        CAST(ss.net_profit AS decimal(10,2)) AS total_profit,
        1 AS level
    FROM 
        store s
    LEFT JOIN (
        SELECT
            ss_store_sk,
            SUM(ss_net_profit) AS net_profit
        FROM 
            store_sales
        GROUP BY
            ss_store_sk
    ) ss ON s.s_store_sk = ss.ss_store_sk
    UNION ALL
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_market_id,
        CAST(ss.net_profit AS decimal(10,2)) AS total_profit,
        sh.level + 1
    FROM 
        store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk 
    WHERE 
        sh.level < 3
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(
            COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)
        ) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
profit_summary AS (
    SELECT
        sh.s_store_id,
        sh.s_store_name,
        SUM(sh.total_profit) AS aggregate_profit,
        COUNT(c.c_customer_sk) AS unique_customers,
        AVG(c.total_spent) AS average_spent
    FROM 
        sales_hierarchy sh
    LEFT JOIN customer_data c ON sh.s_store_sk = c.c_current_addr_sk
    GROUP BY 
        sh.s_store_id, sh.s_store_name
)
SELECT 
    p.s_store_name,
    p.aggregate_profit,
    p.unique_customers,
    COALESCE(p.average_spent, 0) AS average_spent,
    CASE 
        WHEN p.average_spent IS NULL THEN 'No Sales'
        WHEN p.average_spent < 100 THEN 'Low Value'
        WHEN p.average_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_segment
FROM 
    profit_summary p
ORDER BY 
    p.aggregate_profit DESC;
