
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND sh.ss_sold_date_sk > ss.ss_sold_date_sk
    GROUP BY 
        sh.s_store_sk, sh.ss_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
profit_by_customer AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        SUM(sh.total_profit) AS total_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_hierarchy sh ON ci.c_customer_sk = sh.s_store_sk
    GROUP BY 
        ci.c_customer_sk, ci.cd_gender
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    COALESCE(pb.total_profit, 0) AS total_profit,
    ci.order_count,
    RANK() OVER (PARTITION BY ci.cd_gender ORDER BY COALESCE(pb.total_profit, 0) DESC) AS profit_rank
FROM 
    customer_info ci
LEFT JOIN 
    profit_by_customer pb ON ci.c_customer_sk = pb.c_customer_sk
WHERE 
    ci.order_count > 5
ORDER BY 
    ci.cd_gender, profit_rank;
