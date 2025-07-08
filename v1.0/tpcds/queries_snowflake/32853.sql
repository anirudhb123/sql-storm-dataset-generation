
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.cd_demo_sk, 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE 
        c.c_first_name IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.cd_demo_sk, 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count,
        h.level + 1
    FROM 
        customer c
    JOIN 
        customer_hierarchy h ON c.c_current_cdemo_sk = h.cd_demo_sk
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk 
    WHERE 
        h.level < 3
),

latest_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        ws_bill_customer_sk
),

high_value_customers AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_gender,
        ch.cd_dep_count,
        COALESCE(ls.total_net_profit, 0) AS total_net_profit
    FROM 
        customer_hierarchy ch
    LEFT JOIN 
        latest_sales ls ON ch.c_customer_sk = ls.ws_bill_customer_sk
    WHERE 
        ch.cd_purchase_estimate > 1000
)

SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_dep_count,
    hvc.total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY hvc.cd_gender ORDER BY hvc.total_net_profit DESC) AS rank
FROM 
    high_value_customers hvc
WHERE 
    hvc.total_net_profit IS NOT NULL
ORDER BY 
    hvc.total_net_profit DESC
LIMIT 10;
